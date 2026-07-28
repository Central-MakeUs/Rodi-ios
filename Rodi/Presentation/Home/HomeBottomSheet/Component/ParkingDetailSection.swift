//
//  ParkingDetailSection.swift
//  Rodi
//

import SwiftUI

struct ParkingDetailSection: View {
    let parking: RodiParkingInfo

    private var rows: [DetailInfoRowData] {
        var rows: [DetailInfoRowData] = []

        if let parkingType = parking.parkingType, !parkingType.isEmpty {
            rows.append(DetailInfoRowData(title: "유형", value: parkingType))
        }

        if let capacity = parking.capacity {
            rows.append(DetailInfoRowData(title: "수용 대수", value: "\(capacity)대"))
        }

        if let isFree = parking.isFree {
            rows.append(DetailInfoRowData(title: "요금", value: isFree ? "무료" : "유료"))
        }

        rows.append(contentsOf: feeRows)
        rows.append(contentsOf: operatingRows)

        if let paymentMethods = parking.paymentMethods, !paymentMethods.isEmpty {
            rows.append(DetailInfoRowData(title: "결제", value: paymentMethods.joined(separator: ", ")))
        }

        if let hasAccessibleSpace = parking.hasAccessibleSpace {
            rows.append(DetailInfoRowData(title: "장애인 구역", value: hasAccessibleSpace ? "있음" : "확인 필요"))
        }

        if let operatorName = parking.operator, !operatorName.isEmpty {
            rows.append(DetailInfoRowData(title: "운영", value: operatorName))
        }

        if let phone = parking.phone, !phone.isEmpty {
            rows.append(DetailInfoRowData(title: "문의", value: phone))
        }

        if let note = parking.note, !note.isEmpty {
            rows.append(DetailInfoRowData(title: "비고", value: note))
        }

        return rows
    }

    private var feeRows: [DetailInfoRowData] {
        guard let feeInfo = parking.feeInfo else { return [] }
        var rows: [DetailInfoRowData] = []

        if let baseMinutes = feeInfo.baseMinutes, let baseFee = feeInfo.baseFee {
            rows.append(DetailInfoRowData(title: "기본 요금", value: "\(baseMinutes)분 \(formatWon(baseFee))"))
        }

        if let addUnitMinutes = feeInfo.addUnitMinutes, let addUnitFee = feeInfo.addUnitFee {
            rows.append(DetailInfoRowData(title: "추가 요금", value: "\(addUnitMinutes)분당 \(formatWon(addUnitFee))"))
        }

        if let dayTicketHours = feeInfo.dayTicketHours, let dayTicketFee = feeInfo.dayTicketFee {
            rows.append(DetailInfoRowData(title: "일권", value: "\(dayTicketHours)시간 \(formatWon(dayTicketFee))"))
        }

        if let monthlyFee = feeInfo.monthlyFee {
            rows.append(DetailInfoRowData(title: "월 정기권", value: formatWon(monthlyFee)))
        }

        return rows
    }

    private var operatingRows: [DetailInfoRowData] {
        guard let hours = parking.operatingHours else { return [] }
        var rows: [DetailInfoRowData] = []

        if let weekday = hours.weekday, !weekday.isEmpty {
            rows.append(DetailInfoRowData(title: "평일", value: weekday))
        }

        if let saturday = hours.saturday, !saturday.isEmpty {
            rows.append(DetailInfoRowData(title: "토요일", value: saturday))
        }

        if let holiday = hours.holiday, !holiday.isEmpty {
            rows.append(DetailInfoRowData(title: "공휴일", value: holiday))
        }

        return rows
    }

    var body: some View {
        DetailInfoSection(title: "주차장 정보") {
            VStack(spacing: 10) {
                ForEach(rows) { row in
                    DetailInfoRow(row: row)
                }
            }
        }
    }

    private func formatWon(_ value: Int) -> String {
        "\(NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal))원"
    }
}
