import Foundation

struct PlaceParkingDetailDTO: Decodable {
    let roadAddress: String?
    let lotAddress: String?
    let managementNo: String?
    let parkingType: String?
    let capacity: Int?
    let isFree: Bool?
    let feeInfo: PlaceFeeInfoDTO?
    let operatingHours: PlaceOperatingHoursDTO?
}
