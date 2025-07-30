using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Dynamics.Commerce.Runtime;
using Microsoft.Dynamics.Commerce.Runtime.DataAccess.SqlServer;
using Microsoft.Dynamics.Commerce.Runtime.DataModel;
using Microsoft.Dynamics.Commerce.Runtime.DataServices.Messages;
using Microsoft.Dynamics.Commerce.Runtime.Messages;
using Microsoft.Dynamics.Commerce.Runtime.RealtimeServices.Messages;

namespace CommerceRuntime.RequestHandlers
{
    /// <summary>
    /// Request handler to create or update customer data asynchronously.
    /// This handler persists the customer record locally, updates extended properties,
    /// and attempts to push extended property changes to headquarters via real-time services.
    /// </summary>
    internal class CreateUpdateCustomerDataRequestHandler
        : SingleAsyncRequestHandler<CreateOrUpdateCustomerDataRequest>
    {
        protected override async Task<Response> Process(CreateOrUpdateCustomerDataRequest request)
        {
            // Validate that the request is not null
            ThrowIf.Null(request, nameof(request));

            // 1) Persist the core customer record into the local channel database by invoking next handler
            var channelResponse = await this
                .ExecuteNextAsync<SingleEntityDataServiceResponse<Customer>>(request)
                .ConfigureAwait(false);

            // 2) Extract the extended property "REFNOEXT" from the request's customer entity, or default to empty string
            string refNoExt = request.Customer.ExtensionProperties?
                                  .Where(p => p.Key.Equals("REFNOEXT", StringComparison.OrdinalIgnoreCase))
                                  .Select(p => p.Value.StringValue)
                                  .FirstOrDefault()
                              ?? string.Empty;

            // 3) Upsert the REFNOEXT value into the local extension table using a stored procedure call
            using (var dbContext = new SqlServerDatabaseContext(request.RequestContext))
            {
                var spParams = new ParameterSet();
                spParams.Add("AccountNum", request.Customer.AccountNumber);
                spParams.Add("REFNOEXT", refNoExt);

                await dbContext.ExecuteStoredProcedureNonQueryAsync(
                        "[ext].[UPDATECUSTOMEREXTENEDPROPERTIES]",
                        spParams,
                        resultSettings: null)
                    .ConfigureAwait(false);
            }

            // 4) Attempt to push the updated REFNOEXT property to headquarters via real-time service call
            try
            {
                var rtRequest = new InvokeExtensionMethodRealtimeRequest(
                    "UpdateCustomerExtendedProperties",
                    request.Customer.AccountNumber,
                    refNoExt);

                var rtResponse = await request.RequestContext
                    .ExecuteAsync<InvokeExtensionMethodRealtimeResponse>(rtRequest)
                    .ConfigureAwait(false);

                // Validate the response container contains at least two elements: success flag and message
                if (rtResponse?.Result != null && rtResponse.Result.Count >= 2)
                {
                    bool success = (bool)rtResponse.Result[0];
                    string message = rtResponse.Result[1]?.ToString();

                    // If the update failed on HQ side, throw a business exception with message
                    if (!success)
                    {
                        throw new CommerceException("UpdateCustomerExtendedPropertiesFailed", message);
                    }
                }
                else
                {
                    // Response is missing or malformed; throw an exception to indicate this
                    throw new CommerceException(
                        "InvalidHQResponse",
                        "Headquarters response was missing or malformed.");
                }
            }
            catch (CommunicationException)
            {
                // HQ real-time endpoint not available or returned HTTP 204 No Content → safely ignore
            }
            // Allow CommerceException to propagate to surface HQ business errors
            catch
            {
                // Catch and ignore all other exceptions to avoid breaking local processing
            }

            // 5) Return the original response from the local channel data persistence operation
            return channelResponse;
        }
    }
}
