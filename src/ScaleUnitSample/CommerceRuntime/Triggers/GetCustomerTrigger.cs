using System;
using System.Collections.Generic;
using System.Linq;                         // ← make sure you have this
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
    internal class GetCustomerTrigger : IRequestTriggerAsync
    {
        public IEnumerable<Type> SupportedRequestTypes => new[]
        {
            typeof(GetCustomerDataRequest),
            typeof(GetCustomersDataRequest)
        };

        // ← **New no-op implementation** to satisfy the interface
        public Task OnExecuting(Request request)
        {
            // you can leave this empty if you don’t need pre‑execution logic
            return Task.CompletedTask;
        }

        public async Task OnExecuted(Request request, Response response)
        {
            ThrowIf.Null(request, nameof(request));
            ThrowIf.Null(response, nameof(response));

            switch (request)
            {
                case GetCustomerDataRequest _:
                    var singleResponse = (SingleEntityDataServiceResponse<Customer>)response;
                    Customer customer = singleResponse.Entity;         // now strongly typed
                    if (customer != null)
                    {
                        var query = new SqlPagedQuery(QueryResultSettings.SingleRecord)
                        {
                            DatabaseSchema = "ext",
                            Select = new ColumnSet(new[] { "REFNOEXT" }),
                            From = "CONTOSOCUSTTABLEEXTENSION",
                            Where = "ACCOUNTNUM = @accountNum"
                        };
                        query.Parameters["@accountNum"] = customer.AccountNumber;

                        using (var db = new DatabaseContext(request.RequestContext))
                        {
                            var extResp = await db.ReadEntityAsync<ExtensionsEntity>(query).ConfigureAwait(false);
                            var ext = extResp.FirstOrDefault();         // LINQ extension
                            var refNoExt = ext?.GetProperty("REFNOEXT");

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
                    var listResponse = (EntityDataServiceResponse<Customer>)response;
                    foreach (Customer item in listResponse.PagedEntityCollection)   // strongly typed
                    {
                        var query = new SqlPagedQuery(QueryResultSettings.SingleRecord)
                        {
                            DatabaseSchema = "ext",
                            Select = new ColumnSet(new[] { "REFNOEXT" }),
                            From = "CONTOSOCUSTTABLEEXTENSION",
                            Where = "ACCOUNTNUM = @accountNum"
                        };
                        query.Parameters["@accountNum"] = item.AccountNumber;

                        using (var db = new DatabaseContext(request.RequestContext))
                        {
                            var extResp = await db.ReadEntityAsync<ExtensionsEntity>(query).ConfigureAwait(false);
                            var ext = extResp.FirstOrDefault();
                            var refNoExt = ext?.GetProperty("REFNOEXT");

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
                    break;
            }
        }
    }
}
