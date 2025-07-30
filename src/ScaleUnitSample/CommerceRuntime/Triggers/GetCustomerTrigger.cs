using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Dynamics.Commerce.Runtime;
using Microsoft.Dynamics.Commerce.Runtime.Data;
using Microsoft.Dynamics.Commerce.Runtime.DataModel;
using Microsoft.Dynamics.Commerce.Runtime.DataServices.Messages;
using Microsoft.Dynamics.Commerce.Runtime.Messages;
using Microsoft.Dynamics.Commerce.Runtime.DataAccess.SqlServer;
using Microsoft.Dynamics.Commerce.Runtime.RealtimeServices.Messages;

namespace CommerceRuntime.Triggers
{
    /*
     * Summary:
     * This class implements an asynchronous request trigger to extend customer data retrieval.
     * It hooks into the GetCustomerDataRequest and GetCustomersDataRequest requests to add
     * the extended property "REFNOEXT" from a custom extension table (CONTOSOCUSTTABLEEXTENSION).
     * The trigger fetches this extra property from the extension table and appends it to the
     * customer entities’ ExtensionProperties collection, enhancing the returned customer data.
     */
    internal class GetCustomerTrigger : IRequestTriggerAsync
    {
        // Define which request types this trigger supports
        public IEnumerable<Type> SupportedRequestTypes => new[]
        {
            typeof(GetCustomerDataRequest),    // Single customer request
            typeof(GetCustomersDataRequest)    // Multiple customers request
        };

        // ← **New no-op implementation** to satisfy the interface
        // This method is called before the request executes; left empty as no pre-execution logic is needed
        public Task OnExecuting(Request request)
        {
            return Task.CompletedTask;
        }

        // This method is called after the request execution to enrich the response with extended properties
        public async Task OnExecuted(Request request, Response response)
        {
            // Validate input arguments
            ThrowIf.Null(request, nameof(request));
            ThrowIf.Null(response, nameof(response));

            switch (request)
            {
                case GetCustomerDataRequest _:
                    // Handle single customer response
                    var singleResponse = (SingleEntityDataServiceResponse<Customer>)response;
                    Customer customer = singleResponse.Entity;  // Strongly typed customer entity
                    if (customer != null)
                    {
                        // Build query to fetch REFNOEXT from extension table for this customer
                        var query = new SqlPagedQuery(QueryResultSettings.SingleRecord)
                        {
                            DatabaseSchema = "ext",
                            Select = new ColumnSet(new[] { "REFNOEXT" }),
                            From = "CONTOSOCUSTTABLEEXTENSION",
                            Where = "ACCOUNTNUM = @accountNum"
                        };
                        query.Parameters["@accountNum"] = customer.AccountNumber;

                        // Execute query and fetch the extension data
                        using (var db = new DatabaseContext(request.RequestContext))
                        {
                            var extResp = await db.ReadEntityAsync<ExtensionsEntity>(query).ConfigureAwait(false);
                            var ext = extResp.FirstOrDefault();  // Get the first or default result
                            var refNoExt = ext?.GetProperty("REFNOEXT");

                            // If the extended REFNOEXT property is found, add it to the customer's ExtensionProperties
                            if (refNoExt != null)
                            {
                                customer.ExtensionProperties.Add(new CommerceProperty
                                {
                                    Key = "REFNOEXT",
                                    Value = refNoExt.ToString()
                                });
                            }
                        }
                    }
                    break;

                case GetCustomersDataRequest _:
                    // Handle multiple customers response
                    var listResponse = (EntityDataServiceResponse<Customer>)response;
                    foreach (Customer item in listResponse.PagedEntityCollection)  // Strongly typed collection
                    {
                        // Build query to fetch REFNOEXT for each customer in the list
                        var query = new SqlPagedQuery(QueryResultSettings.SingleRecord)
                        {
                            DatabaseSchema = "ext",
                            Select = new ColumnSet(new[] { "REFNOEXT" }),
                            From = "CONTOSOCUSTTABLEEXTENSION",
                            Where = "ACCOUNTNUM = @accountNum"
                        };
                        query.Parameters["@accountNum"] = item.AccountNumber;

                        // Execute query and fetch extension data for each customer
                        using (var db = new DatabaseContext(request.RequestContext))
                        {
                            var extResp = await db.ReadEntityAsync<ExtensionsEntity>(query).ConfigureAwait(false);
                            var ext = extResp.FirstOrDefault();
                            var refNoExt = ext?.GetProperty("REFNOEXT");

                            // If found, add the REFNOEXT property to the customer's ExtensionProperties
                            if (refNoExt != null)
                            {
                                item.ExtensionProperties.Add(new CommerceProperty
                                {
                                    Key = "REFNOEXT",
                                    Value = refNoExt.ToString()
                                });
                            }
                        }
                    }
                    break;

                default:
                    // For any unsupported request types, do nothing
                    break;
            }
        }
    }
}
