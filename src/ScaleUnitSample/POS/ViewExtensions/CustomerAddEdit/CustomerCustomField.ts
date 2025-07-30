import {
    CustomerAddEditCustomControlBase,
    ICustomerAddEditCustomControlState,
    ICustomerAddEditCustomControlContext,
    CustomerAddEditCustomerUpdatedData
} from "PosApi/Extend/Views/CustomerAddEditView";
import { ObjectExtensions } from "PosApi/TypeExtensions";
import { ProxyEntities } from "PosApi/Entities";
import * as Controls from "PosApi/Consume/Controls";

/*
 * Summary:
 * This class implements a custom control for the Customer Add/Edit view in POS.
 * It adds support for the extended customer field "REFNOEXT" allowing users to view
 * and edit this custom field within the POS interface.
 * The control handles initialization, binding to the DOM element,
 * updating the extension property on user input, and maintaining the customer data state.
 */
export default class CustomerCustomField extends CustomerAddEditCustomControlBase {
    private static readonly TEMPLATE_ID: string = "Contoso_Pos_Extensibility_Samples_CustomerCustomField";

    public refnoext: string = "";
    public customerIsPerson: boolean = false;
    public dataList: Controls.IDataList<ProxyEntities.Customer>;
    public readonly title: string;
    private _state: ICustomerAddEditCustomControlState;

    constructor(id: string, context: ICustomerAddEditCustomControlContext) {
        super(id, context);
        this.refnoext = "";
        this.customerIsPerson = false;
        // Event handler to track whether the current customer is a person
        this.customerUpdatedHandler = (data: CustomerAddEditCustomerUpdatedData) => {
            this.customerIsPerson =
                data.customer.CustomerTypeValue === ProxyEntities.CustomerType.Person;
        };
    }

    /**
     * Initializes the control with the given page state.
     * Sets visibility and customer type flag based on initial data.
     * @param state The initial state of the page used to initialize the control.
     */
    public init(state: ICustomerAddEditCustomControlState): void {
        this._state = state;
        if (!this._state.isSelectionMode) {
            this.isVisible = true;
            this.customerIsPerson =
                state.customer.CustomerTypeValue === ProxyEntities.CustomerType.Person;
        }
    }

    /**
     * Binds the control to a specified HTML element.
     * Clones the HTML template, appends it, and sets up event handlers.
     * Initializes the input field value from the customer's extension properties.
     * @param element The element to which the control should be bound.
     */
    public onReady(element: HTMLElement): void {
        const templateElement = document.getElementById(CustomerCustomField.TEMPLATE_ID);
        const templateClone = templateElement.cloneNode(true);
        element.appendChild(templateClone);

        // Get the input element for REFNOEXT and set up onchange event
        const idRefNoExt = element.querySelector("#IDREFNOEXT") as HTMLInputElement;
        idRefNoExt.onchange = () => {
            this.updateExtensionField(idRefNoExt.value);
        };

        // Initialize the input value from the customer's extension properties if available
        let sampleExtensionPropertyValue = "";
        if (!ObjectExtensions.isNullOrUndefined(this.customer.ExtensionProperties)) {
            const sampleProperties = this.customer.ExtensionProperties.filter(
                (extensionProperty: ProxyEntities.CommerceProperty) =>
                    extensionProperty.Key === "REFNOEXT"
            );
            sampleExtensionPropertyValue = sampleProperties.length > 0
                ? sampleProperties[0].Value.StringValue
                : "";
        }
        idRefNoExt.value = sampleExtensionPropertyValue;
    }

    /**
     * Updates the REFNOEXT extension property on the customer entity.
     * @param RefNoExt The new value to set for the REFNOEXT property.
     */
    public updateExtensionField(RefNoExt: string): void {
        this._addOrUpdateExtensionProperty("REFNOEXT", {
            StringValue: RefNoExt
        } as ProxyEntities.CommercePropertyValue);
    }

    /**
     * Adds a new extension property or updates an existing one by key.
     * Ensures the customer's ExtensionProperties array is updated accordingly.
     * @param key The key of the extension property to add or update.
     * @param newValue The new value for the extension property.
     */
    private _addOrUpdateExtensionProperty(
        key: string,
        newValue: ProxyEntities.CommercePropertyValue
    ): void {
        const customer = this.customer;
        const extensionProperty = Commerce.ArrayExtensions.firstOrUndefined(
            customer.ExtensionProperties,
            (property: ProxyEntities.CommerceProperty) => property.Key === key
        );

        // If property doesn't exist, create and add it
        if (ObjectExtensions.isNullOrUndefined(extensionProperty)) {
            const newProperty: ProxyEntities.CommerceProperty = {
                Key: key,
                Value: newValue
            };
            if (ObjectExtensions.isNullOrUndefined(customer.ExtensionProperties)) {
                customer.ExtensionProperties = [];
            }
            customer.ExtensionProperties.push(newProperty);
        } else {
            // Otherwise, update existing property's value
            extensionProperty.Value = newValue;
        }

        // Update the customer entity with the modified extension properties
        this.customer = customer;
    }
}
