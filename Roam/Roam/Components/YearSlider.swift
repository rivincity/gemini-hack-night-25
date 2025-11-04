//
//  YearSlider.swift
//  Roam
//
//  Year slider for filtering map pins by year
//

import SwiftUI

struct YearSlider: View {
    @Binding var selectedYear: Int?
    let availableYears: [Int]

    @State private var sliderValue: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            // Selected year indicator
            if let year = selectedYear {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)

                    Text("Showing \(year) Trips")
                        .font(.headline)

                    Spacer()

                    Button {
                        withAnimation {
                            selectedYear = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Show All")
                            Image(systemName: "xmark.circle.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Slider
            if !availableYears.isEmpty {
                VStack(spacing: 8) {
                    Slider(
                        value: $sliderValue,
                        in: 0...Double(availableYears.count - 1),
                        step: 1,
                        onEditingChanged: { editing in
                            if !editing {
                                updateSelectedYear()
                            }
                        }
                    )
                    .accentColor(.accentColor)

                    // Year markers
                    HStack {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)")
                                .font(.caption2)
                                .foregroundColor(selectedYear == year ? .accentColor : .secondary)
                                .fontWeight(selectedYear == year ? .bold : .regular)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            } else {
                Text("No trips yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            // Initialize slider to show all years
            if selectedYear == nil, !availableYears.isEmpty {
                sliderValue = Double(availableYears.count - 1) / 2
            }
        }
        .onChange(of: sliderValue) { oldValue, newValue in
            updateSelectedYear()
        }
    }

    private func updateSelectedYear() {
        guard !availableYears.isEmpty else { return }

        let index = Int(sliderValue.rounded())
        let clampedIndex = min(max(index, 0), availableYears.count - 1)

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedYear = availableYears[clampedIndex]
        }
    }
}

// MARK: - Compact Year Filter (Alternative Design)

struct CompactYearFilter: View {
    @Binding var selectedYear: Int?
    let availableYears: [Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" button
                YearChip(
                    label: "All Years",
                    isSelected: selectedYear == nil,
                    action: {
                        withAnimation {
                            selectedYear = nil
                        }
                    }
                )

                // Year chips
                ForEach(availableYears, id: \.self) { year in
                    YearChip(
                        label: "\(year)",
                        isSelected: selectedYear == year,
                        action: {
                            withAnimation {
                                selectedYear = year
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct YearChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

// MARK: - Date Range Picker

struct DateRangePicker: View {
    @Binding var fromDate: Date
    @Binding var toDate: Date
    @Binding var isPresented: Bool

    var onApply: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Date Range") {
                    DatePicker("From", selection: $fromDate, displayedComponents: .date)
                    DatePicker("To", selection: $toDate, displayedComponents: .date)
                }

                Section("Quick Presets") {
                    Button("This Year") {
                        let now = Date()
                        fromDate = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: now))!
                        toDate = now
                    }

                    Button("Last Year") {
                        let now = Date()
                        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: now)!
                        fromDate = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: lastYear))!
                        toDate = Calendar.current.date(byAdding: .year, value: 1, to: fromDate)!
                    }

                    Button("Last 6 Months") {
                        toDate = Date()
                        fromDate = Calendar.current.date(byAdding: .month, value: -6, to: toDate)!
                    }

                    Button("All Time") {
                        fromDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
                        toDate = Date()
                    }
                }
            }
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Year Slider") {
    VStack {
        Spacer()

        YearSlider(
            selectedYear: .constant(2023),
            availableYears: [2020, 2021, 2022, 2023, 2024]
        )
        .padding()
    }
}

#Preview("Compact Filter") {
    VStack {
        Spacer()

        CompactYearFilter(
            selectedYear: .constant(2023),
            availableYears: [2020, 2021, 2022, 2023, 2024]
        )
        .padding()
    }
}
