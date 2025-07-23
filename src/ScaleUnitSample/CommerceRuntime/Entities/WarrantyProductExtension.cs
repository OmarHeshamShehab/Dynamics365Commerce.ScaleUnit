using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace Contoso.Commerce.Runtime.Entities
{
    using Microsoft.Dynamics.Commerce.Runtime.DataModel;

    public class WarrantyProductExtension : CommerceEntity
    {
        public WarrantyProductExtension() : base("WarrantyProductExtension") { }

        public long ProductRecId { get; set; }
        public string ItemId { get; set; }
        public int WarrantyPeriod { get; set; }
    }
}
