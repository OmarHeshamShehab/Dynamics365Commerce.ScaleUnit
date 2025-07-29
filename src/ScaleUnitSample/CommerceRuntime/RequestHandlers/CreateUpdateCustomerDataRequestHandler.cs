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
    /// Create or update customer data request handler.
    /// </summary>
    internal class CreateUpdateCustomerDataRequestHandler
        : SingleAsyncRequestHandler<CreateOrUpdateCustomerDataRequest>
    {
        protected override async Task<Response> Process(CreateOrUpdateCustomerDataRequest request)
        {
            ThrowIf.Null(request, nameof(request));

            // 1) Persist the core customer record into the channel DB
            var channelResponse = await this
                .ExecuteNextAsync<SingleEntityDataServiceResponse<Customer>>(request)
                .ConfigureAwait(false);

            // 2) Pull out REFNOEXT if supplied (or empty)
            string refNoExt = request.Customer.ExtensionProperties?
                                  .Where(p => p.Key.Equals("REFNOEXT", StringComparison.OrdinalIgnoreCase))
                                  .Select(p => p.Value.StringValue)
                                  .FirstOrDefault()
                              ?? string.Empty;

            // 3) Upsert into our local ext table
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

            // 4) Try to push to HQ via real-time service
            try
            {
                var rtRequest = new InvokeExtensionMethodRealtimeRequest(
                    "UpdateCustomerExtendedProperties",
                    request.Customer.AccountNumber,
                    refNoExt);

                var rtResponse = await request.RequestContext
                    .ExecuteAsync<InvokeExtensionMethodRealtimeResponse>(rtRequest)
                    .ConfigureAwait(false);

                // Validate the two-element container
                if (rtResponse?.Result != null && rtResponse.Result.Count >= 2)
                {
                    bool success = (bool)rtResponse.Result[0];
                    string message = rtResponse.Result[1]?.ToString();

                    if (!success)
                    {
                        // HQ‑side business error: bubble it up
                        throw new CommerceException("UpdateCustomerExtendedPropertiesFailed", message);
                    }
                }
                else
                {
                    // Empty or malformed response: bubble it up
                    throw new CommerceException(
                        "InvalidHQResponse",
                        "Headquarters response was missing or malformed.");
                }
            }
            catch (CommunicationException)
            {
                // HQ real-time endpoint not available or returned 204 → ignore
            }
            // Let CommerceException go through, so real HQ business errors still surface
            catch
            {
                // any other exception → ignore
            }

            // 5) Always return the channel response
            return channelResponse;
        }
    }
}
