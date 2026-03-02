using Microsoft.VisualBasic.ApplicationServices;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RPIIUtility
{
    public class Root
    {
        public bool found { get; set; }
        public string tagId { get; set; }
        public string status { get; set; }
        public string statusClass { get; set; }
        public string unitReferenceNo { get; set; }
        public string type { get; set; }
        public string currentOperator { get; set; }
        public string certificateExpiryDate { get; set; }
        public string certificateUrl { get; set; }
        public string reportUrl { get; set; }
        public string imageUrl { get; set; }
        public List<AnnualReport> annualReports { get; set; }
        public DateTime fetchedAt { get; set; }
        public bool fromCache { get; set; }
    }

    public class AnnualReport
    {
        public string statusClass { get; set; }
        public string url { get; set; }
        public string date { get; set; }
        public string reportNo { get; set; }
        public string inspectionBody { get; set; }
        public string status { get; set; }
        public Details details { get; set; }
        public string detailsError { get; set; }
    }

    public class Details
    {
        public bool found { get; set; }
        public string reportId { get; set; }
        public string id { get; set; }
        public string validFrom { get; set; }
        public string expiryDate { get; set; }
        public string inspectionBody { get; set; }
        public string tagNo { get; set; }
        public string deviceType { get; set; }
        public string serialNumber { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
        public string imageUrl { get; set; }
        public ReportDetails reportDetails { get; set; }
        public Device device { get; set; }
        public Dimensions dimensions { get; set; }
        public UserLimits userLimits { get; set; }
        public Notes notes { get; set; }
        public InspectionSections inspectionSections { get; set; }
        public DateTime fetchedAt { get; set; }
    }

    public class ReportDetails
    {
        public string creationDate { get; set; }
        public string inspectionDate { get; set; }
        public string placeOfInspection { get; set; }
        public string inspector { get; set; }
        public string structureVersion { get; set; }
        public string indoorUseOnly { get; set; }
    }

    public class Device
    {
        public string pipaReferenceNumber { get; set; }
        public string tagNumber { get; set; }
        public string type { get; set; }
        public string name { get; set; }
        public string manufacturer { get; set; }
        public string deviceSerialNumber { get; set; }
        public string dateManufactured { get; set; }
    }

    public class Dimensions
    {
        public string length { get; set; }
        public string width { get; set; }
        public string height { get; set; }
    }

    public class UserLimits
    {
        public int upTo1_0m { get; set; }
        public int upTo1_2m { get; set; }
        public int upTo1_5m { get; set; }
        public int upTo1_8m { get; set; }
    }

    public class Notes
    {
        public string label { get; set; }
    }


    public class InspectionSections
    {
        public List<Structure> structure { get; set; }
        public List<Material> materials { get; set; }
        public List<Anchorage> anchorage { get; set; }
        public List<AreaSurround> areaSurround { get; set; }
        public List<Blower> blowers { get; set; }
        public List<EntranceExitsEvacuation> entranceExitsEvacuation { get; set; }
        public List<Slide> slides { get; set; }
        public List<User> users { get; set; }
        public List<Notes> notes { get; set; }
    }

    public class Structure
    {
        public string label { get; set; }
        public string value { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
        public string notes { get; set; }
    }

    public class Material
    {
        public string label { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
    }

    public class Anchorage
    {
        public string label { get; set; }
        public string value { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
    }

    public class AreaSurround
    {
        public string label { get; set; }
        public string value { get; set; }
        public string notes { get; set; }
    }

    public class Blower
    {
        public string label { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
        public string value { get; set; }
        public string notes { get; set; }
    }

    public class EntranceExitsEvacuation
    {
        public string label { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
        public string value { get; set; }
        public string notes { get; set; }
    }

    public class Slide
    {
        public string label { get; set; }
        public string value { get; set; }
        public string statusClass { get; set; }
        public string status { get; set; }
        public string notes { get; set; }
    }
}
