// ============================================================================
// SAMPLE CODE NOTICE
// 
// THIS SAMPLE CODE IS MADE AVAILABLE AS IS.  MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
// OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
// THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
// NO TECHNICAL SUPPORT IS PROVIDED.  YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
// ============================================================================

/**
 * Detailed Summary:
 * -----------------
 * This asynchronous request trigger extends the Commerce Runtime pipeline to augment channel
 * configuration and customer search results with custom extension data in a thread-safe manner.
 * It intercepts two specific data service requests:
 *   1. GetChannelConfigurationDataRequest: Adds a collection of RetailConfigurationParameters
 *      to the cached ChannelConfiguration entity under the key "ExtConfigurationParameters".
 *      Utilizes a lock to avoid concurrent modifications on the shared cache object.
 *   2. SearchCustomersDataRequest: After retrieving GlobalCustomer entities, queries a
 *      custom SQL table (ext.CONTOSOCUSTTABLEEXTENSION) to fetch a RefNoExt value per
 *      customer based on AccountNumber. Wraps DatabaseContext in a using block to ensure
 *      disposal, and populates each customer's ExtensionProperties with a CommerceProperty.
 *
 * Key Features:
 *   - Thread Safety: Uses lock on the ChannelConfiguration instance to prevent 100% CPU usage
 *     caused by concurrent SetProperty calls on cached objects.
 *   - Asynchronous Execution: Implements IRequestTriggerAsync and uses ConfigureAwait(false)
 *     for both service and SQL queries to avoid deadlocks and optimize responsiveness.
 *   - Extensibility: Adds or updates extension properties without altering the core CRT code,
 *     enabling future enhancements via additional request triggers.
 */

namespace Contoso.CommerceRuntime.Triggers
{
    using Microsoft.Dynamics.Commerce.Runtime;              // Core CRT runtime types (Request, Response, triggers)
    using Microsoft.Dynamics.Commerce.Runtime.Data;         // Data access abstractions (DatabaseContext)
    using Microsoft.Dynamics.Commerce.Runtime.DataModel;    // Entity models (ChannelConfiguration, GlobalCustomer)
    using Microsoft.Dynamics.Commerce.Runtime.DataServices.Messages; // Data service request/response messages
    using Microsoft.Dynamics.Commerce.Runtime.Messages;     // Base request/response types
    using System;                                          // Fundamental .NET types
    using System.Collections.Generic;                      // Collection interfaces
    using System.Linq;                                     // LINQ extensions for collections
    using System.Threading.Tasks;                         // Task-based asynchronous programming

    /// <summary>
    /// Trigger to inject custom configuration and customer extension data into CRT responses.
    /// Implements IRequestTriggerAsync to hook into pre- and post-execution pipelines.
    /// </summary>
    public class ChannelDataServiceRequestTrigger : IRequestTriggerAsync
    {
        // Constant key under which the extension parameters are stored
        public static readonly string PropertyKey = "ExtConfigurationParameters";

        /// <summary>
        /// Specifies the data service request types this trigger will handle.
        /// </summary>
        public IEnumerable<Type> SupportedRequestTypes
        {
            get
            {
                // Return only the requests we want to intercept:
                //  - GetChannelConfigurationDataRequest: enrich channel config
                //  - SearchCustomersDataRequest: enrich customer entities
                return new Type[]
                {
                    typeof(GetChannelConfigurationDataRequest),
                    typeof(SearchCustomersDataRequest)
                };
            }
        }

        /// <summary>
        /// Pre-execution stub: required by IRequestTriggerAsync, no custom logic here.
        /// </summary>
        /// <param name="request">Incoming data service request</param>
        public Task OnExecuting(Request request)
        {
            // No-op: simply complete immediately to satisfy the async signature
            return Task.CompletedTask;
        }

        /// <summary>
        /// Post-execution logic: called after the data service request has been processed.
        /// Adds custom properties based on the request type.
        /// </summary>
        /// <param name="request">Original request message</param>
        /// <param name="response">Response returned by the data service</param>
        public async Task OnExecuted(Request request, Response response)
        {
            switch (request)
            {
                case GetChannelConfigurationDataRequest originalRequest:
                    // Handle channel configuration enrichment
                    var data = response as SingleEntityDataServiceResponse<ChannelConfiguration>;
                    if (data != null && data.Entity != null && data.Entity.GetProperty(PropertyKey) == null)
                    {
                        // Retrieve all retail configuration parameters for the channel asynchronously
                        var configurationParameters = (await request.RequestContext
                            .ExecuteAsync<EntityDataServiceResponse<RetailConfigurationParameter>>(
                                new GetConfigurationParametersDataRequest(originalRequest.ChannelId))
                            .ConfigureAwait(false))
                            .ToList();

                        // Lock on the ChannelConfiguration entity to ensure thread safety
                        lock (data.Entity)
                        {
                            // Double-check the property did not get set by another thread
                            if (data.Entity.GetProperty(PropertyKey) == null)
                            {
                                // Set the extension property with the retrieved parameters
                                data.Entity.SetProperty(PropertyKey, configurationParameters);
                            }
                        }
                    }
                    break;

                case SearchCustomersDataRequest getCustomerSearchResultDataRequest:
                    // Handle customer result enrichment
                    var res = (EntityDataServiceResponse<GlobalCustomer>)response;
                    foreach (var item in res)
                    {
                        string value = string.Empty;  // Default to empty if no data found

                        // Use a DatabaseContext in a using block to ensure disposal
                        using (var databaseContext = new DatabaseContext(request.RequestContext))
                        {
                            // Prepare SQL parameters with the customer's account number
                            var configurationDataParameters = new ParameterSet
                            {
                                ["@AccountNum"] = item.AccountNumber
                            };

                            // Execute the custom SQL query asynchronously
                            var configurationDataSet = await databaseContext
                                .ExecuteQueryDataSetAsync(
                                    "SELECT REFNOEXT FROM ext.CONTOSOCUSTTABLEEXTENSION WHERE ACCOUNTNUM = @AccountNum",
                                    configurationDataParameters)
                                .ConfigureAwait(false);

                            // If at least one row is returned, extract the first column value as string
                            if (configurationDataSet.Tables[0].Rows.Count > 0)
                            {
                                value = configurationDataSet.Tables[0].Rows[0][0] as string;
                            }
                        }  // DatabaseContext.Dispose() is invoked here automatically

                        // Add the retrieved value to the customer's ExtensionProperties
                        item.ExtensionProperties.Add(new CommerceProperty()
                        {
                            Key = "RefNoExt",
                            Value = value
                        });
                    }
                    break;

                default:
                    // Throw if an unsupported request type is encountered
                    throw new NotSupportedException($"Request '{request.GetType()}' is not supported.");
            }
        }
    }
}
