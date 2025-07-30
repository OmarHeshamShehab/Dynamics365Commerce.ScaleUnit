/*
 * Summary:
 * This module implements a custom panel control named ProductAvailabilityPanel
 * for the POS product details page. The panel shows product availability
 * across different stores including location, available inventory,
 * reserved quantity, and on-order quantity.
 *
 * Features:
 * - Extends the base SimpleProductDetailsCustomControlBase class.
 * - Displays a titled panel "Product Availability".
 * - Uses a templated HTML structure identified by TEMPLATE_ID.
 * - Initializes a data list control with four columns for availability info.
 * - Fetches real-time inventory availability data asynchronously for the current product.
 * - Handles errors by logging them.
 * - Only visible when not in selection mode.
 */

import {
    SimpleProductDetailsCustomControlBase,
    ISimpleProductDetailsCustomControlState,
    ISimpleProductDetailsCustomControlContext
} from "PosApi/Extend/Views/SimpleProductDetailsView";

import { InventoryLookupOperationRequest, InventoryLookupOperationResponse } from "PosApi/Consume/OrgUnits";

import { ClientEntities, ProxyEntities } from "PosApi/Entities"

import { ArrayExtensions } from "PosApi/TypeExtensions"

import * as Controls from "PosApi/Consume/Controls"

// Custom control class showing product availability in stores.
export default class ProductAvailabilityPanel extends SimpleProductDetailsCustomControlBase {

    public datalist: Controls.IDataList<ProxyEntities.OrgUnitAvailability> // Data list control showing store availabilities.
    public readonly title: string; // Panel title.
    private static readonly TEMPLATE_ID: string = "Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel" // Template ID for HTML UI.
    private _state: ISimpleProductDetailsCustomControlState; // Holds panel state.
    private _orgUnitAvailabilities: ProxyEntities.OrgUnitAvailability[] = []; // Holds availability data.

    constructor(id: string, context: ISimpleProductDetailsCustomControlContext) {
        super(id, context) // Call base constructor.
        this.title = "Product Availability"; // Set panel title.
    }

    public onReady(element: HTMLElement): void {
        // Clone and append template to container element.
        let templateElement: HTMLElement = document.getElementById(ProductAvailabilityPanel.TEMPLATE_ID);
        let templateClone: Node = templateElement.cloneNode(true);
        element.appendChild(templateClone);

        // Set the panel title text.
        let titleElement: HTMLElement = element.querySelector("#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel_TitleElement");
        titleElement.innerText = this.title;

        // Configure columns and options for the data list control.
        let dataListOptions: Readonly<Controls.IDataListOptions<ProxyEntities.OrgUnitAvailability>> = {
            columns: [
                {
                    title: "Location",
                    ratio: 31,
                    collapseOrder: 4,
                    minWidth: 100,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string => value.OrgUnitLocation.OrgUnitName
                },
                {
                    title: "Inventory",
                    ratio: 23,
                    collapseOrder: 3,
                    minWidth: 60,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string =>
                        ArrayExtensions.hasElements(value.ItemAvailabilities) ? value.ItemAvailabilities[0].AvailableQuantity.toString() : "0"
                },
                {
                    title: "Reserved",
                    ratio: 23,
                    collapseOrder: 1,
                    minWidth: 60,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string =>
                        ArrayExtensions.hasElements(value.ItemAvailabilities) ? value.ItemAvailabilities[0].PhysicalReserved.toString() : "0"
                },
                {
                    title: "Order",
                    ratio: 23,
                    collapseOrder: 2,
                    minWidth: 60,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string =>
                        ArrayExtensions.hasElements(value.ItemAvailabilities) ? value.ItemAvailabilities[0].OrderedSum.toString() : "0"
                }
            ],
            data: this._orgUnitAvailabilities, // Data rows for the data list.
            interactionMode: Controls.DataListInteractionMode.None, // Make list read-only.
        };

        // Create and add the data list control to the panel.
        let dataListRoomElem: HTMLDivElement = element.querySelector("#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel_DataList") as HTMLDivElement;
        this.datalist = this.context.controlFactory.create(this.context.logger.getNewCorrelationId(), "DataList", dataListOptions, dataListRoomElem);
    }

    public init(state: ISimpleProductDetailsCustomControlState): void {
        this._state = state; // Save state for later use.
        let correlationid: string = this.context.logger.getNewCorrelationId(); // Get correlation ID for logging.

        if (!this._state.isSelectionMode) { // Only show panel if not selecting.
            this.isVisible = true; // Make panel visible.

            // Create request to lookup inventory for current product.
            let request: InventoryLookupOperationRequest<InventoryLookupOperationResponse> =
                new InventoryLookupOperationRequest<InventoryLookupOperationResponse>(this._state.product.RecordId, correlationid);

            // Execute request asynchronously.
            this.context.runtime.executeAsync(request)
                .then((result: ClientEntities.ICancelableDataResult<InventoryLookupOperationResponse>) => {
                    if (!result.canceled) { // If request was successful...
                        this._orgUnitAvailabilities = result.data.orgUnitAvailability; // Save availability data.
                        this.datalist.data = this._orgUnitAvailabilities; // Update data list.
                    }
                })
                .catch((reason: any) => {
                    this.context.logger.logError(JSON.stringify(reason), correlationid); // Log errors.
                });
        }
    }
}
