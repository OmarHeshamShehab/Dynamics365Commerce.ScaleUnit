import { ICustomerSearchColumn } from "PosApi/Extend/Views/SearchView";
import { ICustomColumnsContext } from "PosApi/Extend/Views/CustomListColumns";
import { ProxyEntities } from "PosApi/Entities";

export default (context: ICustomColumnsContext): ICustomerSearchColumn[] => {
	return [
		{
			title: context.resources.getString("OHMS_2567"),
			computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.AccountNumber; },
			ratio: 15,
			collapseOrder: 5,
			minWidth: 120
		},
		{
			title: context.resources.getString("OHMS_8591"),
			computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.FullName; },
			ratio: 20,
			collapseOrder: 4,
			minWidth: 200
		},
		{
			title: context.resources.getString("OHMS_4312"),
			computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.ExtensionProperties.filter(p => p.Key === "RefNoExt")[0].Value.StringValue as string; },
			ratio: 25,
			collapseOrder: 1,
			minWidth: 200
		},
		{
			title: context.resources.getString("OHMS_7240"),
			computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.Email; },
			ratio: 20,
			collapseOrder: 2,
			minWidth: 200
		},
		{
			title: context.resources.getString("OHMS_1093"),
			computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.Phone; },
			ratio: 20,
			collapseOrder: 3,
			minWidth: 120
		}
	];
};