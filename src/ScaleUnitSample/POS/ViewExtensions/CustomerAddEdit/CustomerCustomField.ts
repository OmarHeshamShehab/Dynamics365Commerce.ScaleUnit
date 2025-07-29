import {
    CustomerAddEditCustomControlBase,
    ICustomerAddEditCustomControlState,
    ICustomerAddEditCustomControlContext,
    CustomerAddEditCustomerUpdatedData
} from "PosApi/Extend/Views/CustomerAddEditView";
import { ObjectExtensions } from "PosApi/TypeExtensions";
import { ProxyEntities } from "PosApi/Entities";
import * as Controls from "PosApi/Consume/Controls";

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
        this.customerUpdatedHandler = (data: CustomerAddEditCustomerUpdatedData) => {
            this.customerIsPerson =
                data.customer.CustomerTypeValue === ProxyEntities.CustomerType.Person;
        };
    }

    /**
     * Initializes the control.
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
     * Binds the control to the specified element.
     * @param element The element to which the control should be bound.
     */
    public onReady(element: HTMLElement): void {
        const templateElement = document.getElementById(CustomerCustomField.TEMPLATE_ID);
        const templateClone = templateElement.cloneNode(true);
        element.appendChild(templateClone);

        const idRefNoExt = element.querySelector("#IDREFNOEXT") as HTMLInputElement;
        idRefNoExt.onchange = () => {
            this.updateExtensionField(idRefNoExt.value);
        };

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
     * Updates the REFNOEXT extension property on the customer.
     * @param RefNoExt The new value for REFNOEXT.
     */
    public updateExtensionField(RefNoExt: string): void {
        this._addOrUpdateExtensionProperty("REFNOEXT", {
            StringValue: RefNoExt
        } as ProxyEntities.CommercePropertyValue);
    }

    /**
     * Gets the property value from the property bag by its key, optionally creating it if it does not exist.
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
            extensionProperty.Value = newValue;
        }

        this.customer = customer;
    }
}
