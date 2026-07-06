//
//  ExpandableAddressMetaRow.swift
//  Rodi
//

import SwiftUI

struct ExpandableAddressMetaRow: View {
    let item: RodiCourseItem
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image("ic_star")
                    .resizable()
                    .frame(width: 14, height: 14)
                Text(String(format: "%.1f", item.rating))
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.primary)
                Text("･")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(item.districtSummary)
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray800)
                            .lineLimit(1)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.pretendard(size: 9, weight: .medium))
                            .foregroundStyle(RodiColor.gray800)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    AddressLine(label: "도로명", value: item.roadAddressText)
                    AddressLine(label: "지번", value: item.jibunAddressText)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RodiColor.primary50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RodiColor.primary200, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct AddressLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray600)
                .lineLimit(1)

            Text(value)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray800)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
