/**
 * Detailed Summary:
 * -----------------
 * This module customizes the POS customer search results by defining a set of dynamic columns.
 * It exports a default function that accepts a context conforming to ICustomColumnsContext, which
 * provides access to localization, styling, and POS configuration services. The function returns
 * an array of ICustomerSearchColumn objects, each describing how to extract and display specific
 * properties from the GlobalCustomer entity. Key aspects:
 *   - Localization: Column headers are retrieved via context.resources.getString with resource IDs,
 *     ensuring support for multiple languages and regional variations.
 *   - Data Extraction: computeValue callbacks take a GlobalCustomer instance and return a string.
 *     These execute synchronously for each row and should handle potential null or missing data.
 *   - Layout Configuration:
 *       • ratio: Specifies the relative width proportion in the search view's Flex layout.
 *       • minWidth: Enforces a pixel-based minimum to maintain readability at small window sizes.
 *       • collapseOrder: Determines the priority for column visibility when the view is resized—
 *         lower numbers stay visible longer, while higher numbers collapse first.
 *   - Extensibility: The design allows adding or reordering columns without altering the core POS UI.
 *
 * The columns defined here include:
 *   1. Account Number: Primary identifier, least likely to collapse.
 *   2. Full Name: The customer's displayed name.
 *   3. Reference Number: Custom extension property extracted from ExtensionProperties.
 *   4. Email: Contact email address.
 *   5. Phone: Contact phone number.
 *
 * By tuning these parameters, we ensure an optimal balance between information density and
 * interface clarity across devices of varying resolutions.
 */
import { ICustomerSearchColumn } from "PosApi/Extend/Views/SearchView";  // Defines the contract for each search column: title, value computation, and layout settings
import { ICustomColumnsContext } from "PosApi/Extend/Views/CustomListColumns"; // Provides localization, configuration context, and utilities for custom columns
import { ProxyEntities } from "PosApi/Entities";                         // Contains the typed entity definitions, including GlobalCustomer

export default (context: ICustomColumnsContext): ICustomerSearchColumn[] => {
    return [
        {
            // CUSTOMER ACCOUNT NUMBER COLUMN
            // ------------------------------
            // title: Retrieves the localized header using resource key "OHMS_2567".
            // computeValue: Synchronously extracts the AccountNumber field from the GlobalCustomer record.
            //              Ensure this value is not null; it represents the unique customer ID in POS.
            // ratio:      Allocates 15 units of relative width in the flexible layout.
            // minWidth:   Enforces at least 120px width to avoid truncation on narrow views.
            // collapseOrder: When horizontal space is limited, this column will collapse after columns
            //                with lower collapseOrder values, preserving it until near the end.
            title: context.resources.getString("OHMS_2567"),
            computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.AccountNumber; },
            ratio: 15,
            collapseOrder: 5,
            minWidth: 120
        },
        {
            // CUSTOMER FULL NAME COLUMN
            // -------------------------
            // title:       Localized header for the customer's full name, resource key "OHMS_8591".
            // computeValue: Returns the full name string for display; typically in "First Last" format.
            // ratio:       Uses 20 relative width units for a balanced appearance.
            // minWidth:    Minimum 200px to accommodate longer names without ellipsis.
            // collapseOrder: This column collapses after Reference Number and Email but before Account Number.
            title: context.resources.getString("OHMS_8591"),
            computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.FullName; },
            ratio: 20,
            collapseOrder: 4,
            minWidth: 200
        },
        {
            // CUSTOMER REFERENCE NUMBER COLUMN (EXTENSION PROPERTY)
            // -----------------------------------------------------
            // title:       Localized header via "OHMS_4312", e.g., "Reference Number".
            // computeValue: Filters the ExtensionProperties array for the entry with Key "RefNoExt".
            //               Returns its StringValue; casts to string for type safety.
            //               Note: Assumes the property exists; consider adding null checks if optional.
            // ratio:       Set to 25 units to allow room for potentially long reference codes.
            // minWidth:    200px minimum to ensure readability of reference strings.
            // collapseOrder: Highest priority (1) to remain visible longest when space is low.
            title: context.resources.getString("OHMS_4312"),
            computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.ExtensionProperties.filter(p => p.Key === "RefNoExt")[0].Value.StringValue as string; },
            ratio: 25,
            collapseOrder: 1,
            minWidth: 200
        },
        {
            // CUSTOMER EMAIL COLUMN
            // ---------------------
            // title:       Localized header "Email" via resource key "OHMS_7240".
            // computeValue: Returns the Email property of the customer; used for follow-up communications.
            // ratio:       20 units in the flex layout.
            // minWidth:    200px to prevent cutoff of typical email addresses.
            // collapseOrder: Moderate priority (2); collapses only after the Reference Number column.
            title: context.resources.getString("OHMS_7240"),
            computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.Email; },
            ratio: 20,
            collapseOrder: 2,
            minWidth: 200
        },
        {
            // CUSTOMER PHONE COLUMN
            // ---------------------
            // title:       Localized header "Phone" via "OHMS_1093".
            // computeValue: Extracts the Phone field; supports multiple formats (string with country code).
            // ratio:       20 relative units to display phone numbers clearly.
            // minWidth:    120px minimum to show area codes without truncation.
            // collapseOrder: Lower priority (3); collapses after Email and Full Name when necessary.
            title: context.resources.getString("OHMS_1093"),
            computeValue: (row: ProxyEntities.GlobalCustomer): string => { return row.Phone; },
            ratio: 20,
            collapseOrder: 3,
            minWidth: 120
        }
    ];
};
