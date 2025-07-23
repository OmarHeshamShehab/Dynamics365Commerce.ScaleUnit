// We are bringing in (importing) some special tools and blueprints from other files so we can use them here.
import {
    SimpleProductDetailsCustomControlBase, // This is like a recipe for making a special panel on the product details page.
    // ?? In Commerce: Provides the basic building block to create a custom control that plugs into the POS product details page.
    ISimpleProductDetailsCustomControlState, // This is a blueprint for what the state (current info) of our panel looks like.
    // ?? In Commerce: Describes what information about the product or page the control can use, like product ID or selection mode.
    ISimpleProductDetailsCustomControlContext // This is a blueprint for the context (environment and helpers) our panel can use.
    // ?? In Commerce: Gives access to helpers like loggers, control factories, runtime services, and other POS utilities.
} from "PosApi/Extend/Views/SimpleProductDetailsView";

// This import brings in two things for looking up inventory (how much stuff we have) in different stores.
// ?? In Commerce: Lets your control ask the Commerce backend about stock levels (request) and handle the response with availability data (response).
import { InventoryLookupOperationRequest, InventoryLookupOperationResponse } from "PosApi/Consume/OrgUnits";

// This import brings in two big groups of blueprints for different things we might use, like products and stores.
// ?? In Commerce: Provides the data types and models used in POS (like OrgUnit, Product, Inventory data).
import { ClientEntities, ProxyEntities } from "PosApi/Entities"

// This import brings in some helpers for working with arrays (lists of things).
// ?? In Commerce: Gives helper methods to safely check, filter, or handle lists/arrays (for example, checking if an availability list has data).
import { ArrayExtensions } from "PosApi/TypeExtensions"

// This import brings in all the controls (like buttons and lists) we can use to show things on the screen.
// ?? In Commerce: Provides the standard UI elements for POS (like DataList, Buttons) to display information to users.
import * as Controls from "PosApi/Consume/Controls"

// We are making a new panel (a special box on the screen) that shows product availability.
// This panel is built using the base class we imported above.
// ?? In Commerce: This is the custom control that adds a product availability panel to the POS product details page.

export default class ProductAvailabilityPanel extends SimpleProductDetailsCustomControlBase {

    // This is a list control that will show the availability of products in different stores.
    public datalist: Controls.IDataList<ProxyEntities.OrgUnitAvailability>
    // This is the title (name) of our panel. It will say "Product Availability".
    public readonly title: string;
    // This is a special name for our panel's template (the design of how it looks).
    private static readonly TEMPLATE_ID: string = "Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel"
    // This will hold the current state (info) of our panel.
    private _state: ISimpleProductDetailsCustomControlState;
    // This is a list that will hold the availability info for each store.
    private _orgUnitAvailabilities: ProxyEntities.OrgUnitAvailability[] = [];

    // This is the constructor. It is called when we make a new panel.
    // It needs an id (name) and a context (helpers and info about where we are).
    constructor(id: string, context: ISimpleProductDetailsCustomControlContext) {
        // We call the base class constructor to set things up.
        super(id, context)
        // We set the title of our panel.
        this.title = "Product Availability";
    }

    // This function is called when our panel is ready to be shown on the screen.
    public onReady(element: HTMLElement): void {
        // We find the template (design) for our panel by its special name.
        let templateElement: HTMLElement = document.getElementById(ProductAvailabilityPanel.TEMPLATE_ID);
        // We make a copy of the template so we can use it.
        let templateClone: Node = templateElement.cloneNode(true);
        // We add the copied template to our panel's place on the screen.
        element.appendChild(templateClone);

        // We find the place in our panel where the title should go.
        let titleElement: HTMLElement = element.querySelector("#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel_TitleElement");
        // We set the text of the title to "Product Availability".
        titleElement.innerText = this.title;

        // We set up the options for our data list (the table that shows the info).
        let dataListOptions: Readonly<Controls.IDataListOptions<ProxyEntities.OrgUnitAvailability>> = {
            // These are the columns (vertical sections) in our table.
            columns: [
                {
                    // The first column shows the store location.
                    title: "Location",
                    ratio: 31,
                    collapseOrder: 4,
                    minWidth: 100,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string => {
                        return value.OrgUnitLocation.OrgUnitName;
                    }
                },
                {
                    // The second column shows how much inventory is available.
                    title: "Inventory",
                    ratio: 23,
                    collapseOrder: 3,
                    minWidth: 60,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string => {
                        return ArrayExtensions.hasElements(value.ItemAvailabilities) ? value.ItemAvailabilities[0].AvailableQuantity.toString() : "0";
                    }
                },
                {
                    // The third column shows how much is reserved.
                    title: "Reserved",
                    ratio: 23,
                    collapseOrder: 1,
                    minWidth: 60,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string => {
                        return ArrayExtensions.hasElements(value.ItemAvailabilities) ? value.ItemAvailabilities[0].PhysicalReserved.toString() : "0";
                    }
                },
                {
                    // The fourth column shows how much is on order.
                    title: "Order",
                    ratio: 23,
                    collapseOrder: 2,
                    minWidth: 60,
                    computeValue: (value: ProxyEntities.OrgUnitAvailability): string => {
                        return ArrayExtensions.hasElements(value.ItemAvailabilities) ? value.ItemAvailabilities[0].OrderedSum.toString() : "0";
                    }
                }
            ],
            // This is the data (rows) for our table. Right now, it's empty.
            data: this._orgUnitAvailabilities,
            // This says that the list is just for showing info, not for clicking.
            interactionMode: Controls.DataListInteractionMode.None,
        };
        // We find the place in our panel where the data list should go.
        let dataListRoomElem: HTMLDivElement = element.querySelector("#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel_DataList") as HTMLDivElement;
        // We create the data list and put it in our panel.
        this.datalist = this.context.controlFactory.create(this.context.logger.getNewCorrelationId(), "DataList", dataListOptions, dataListRoomElem);
    }

    // This function is called to set up our panel with the current state (info).
    public init(state: ISimpleProductDetailsCustomControlState): void {
        // We save the state so we can use it later.
        this._state = state;
        // We get a new special id for logging and tracking.
        let correlationid: string = this.context.logger.getNewCorrelationId();

        // If we are not in selection mode (just showing info, not picking something)...
        if (!this._state.isSelectionMode) {
            // We make our panel visible.
            this.isVisible = true;
            // We make a request to look up inventory for the current product.
            let request: InventoryLookupOperationRequest<InventoryLookupOperationResponse> =
                new InventoryLookupOperationRequest<InventoryLookupOperationResponse>
                    (this._state.product.RecordId, correlationid);
            // We ask the system to run our request. This is like saying, "Please go get the info!"
            this.context.runtime.executeAsync(request)
                // When the info comes back, we use .then to say what to do with it.
                .then((result: ClientEntities.ICancelableDataResult<InventoryLookupOperationResponse>) => {
                    // If the request was not canceled...
                    if (!result.canceled) {
                        // We save the list of store availabilities.
                        this._orgUnitAvailabilities = result.data.orgUnitAvailability;
                        // We update our data list to show the new info.
                        this.datalist.data = this._orgUnitAvailabilities;
                    }
                })
                // If something goes wrong, .catch tells us what to do.
                .catch((reason: any) => {
                    // We log the error so we can see what happened.
                    this.context.logger.logError(JSON.stringify(reason), correlationid);
                });
        }
    }
}