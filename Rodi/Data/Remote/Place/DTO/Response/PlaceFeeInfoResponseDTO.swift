import Foundation

struct PlaceFeeInfoDTO: Decodable {
    let baseMinutes: Int?
    let baseFee: Int?
    let addUnitMinutes: Int?
    let addUnitFee: Int?
    let dayTicketHours: Int?
    let dayTicketFee: Int?
    let monthlyFee: Int?
}
