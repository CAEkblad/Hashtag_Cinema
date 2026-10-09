import SwiftUI

struct BookingView: View {
    @Environment(CinemaStore.self) private var store
    @State private var selectedService: ServiceType?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Book a pro shoot")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tampa Bay crew. $500 deposit holds your date, the balance is charged on delivery.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ForEach(ServiceType.allCases) { service in
                    Button {
                        selectedService = service
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: service.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Theme.red)
                                .frame(width: 46, height: 46)
                                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.name)
                                    .font(.cinema(16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(service.detail)
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.leading)
                                Text("About \(service.hours) hr on site")
                                    .font(.cinema(12, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }

                if !store.bookings.isEmpty {
                    SectionHeader(title: "Your bookings")
                    ForEach(store.bookings.sorted { $0.date < $1.date }) { booking in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(booking.service.name)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(booking.date.shortDay) at \(booking.date.timeOnly)")
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Pill(text: booking.status.title, icon: "checkmark.seal.fill")
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedService) { service in
            BookingFormView(service: service)
        }
    }
}

struct BookingFormView: View {
    let service: ServiceType

    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var day = Calendar.current.startOfDay(for: Date().addingTimeInterval(60 * 60 * 24))
    @State private var slot: Int?
    @State private var address = ""
    @State private var notes = ""
    @State private var isPaying = false
    @State private var confirmed: Booking?

    private let slots = [8, 10, 13, 16]

    private var days: [Date] {
        let start = Calendar.current.startOfDay(for: Date())
        return (1...14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    /// Mock availability. Replace with free/busy from the #Cinema Shoots calendar.
    private func isTaken(_ hour: Int, on day: Date) -> Bool {
        let dayNumber = Calendar.current.component(.day, from: day)
        return (dayNumber + hour) % 3 == 0
    }

    private var chosenDate: Date? {
        guard let slot else { return nil }
        return Calendar.current.date(bySettingHour: slot, minute: 0, second: 0, of: day)
    }

    private var canPay: Bool {
        chosenDate != nil && (!service.needsAddress || !address.isEmpty) && !isPaying
    }

    var body: some View {
        NavigationStack {
            Group {
                if let confirmed {
                    confirmation(confirmed)
                } else {
                    form
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(service.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(confirmed == nil ? "Cancel" : "Done") { dismiss() }
                }
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Pick a day")
                    .font(.cinema(17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(days, id: \.self) { option in
                            let isOn = Calendar.current.isDate(option, inSameDayAs: day)
                            Button {
                                day = option
                                slot = nil
                            } label: {
                                VStack(spacing: 4) {
                                    Text(option.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.cinema(12, weight: .semibold))
                                    Text(option.formatted(.dateTime.day()))
                                        .font(.cinema(20, weight: .bold))
                                }
                                .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                                .frame(width: 58, height: 70)
                                .background(isOn ? Theme.red : Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Pick a time")
                    .font(.cinema(17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(slots, id: \.self) { hour in
                        let taken = isTaken(hour, on: day)
                        Button {
                            slot = hour
                        } label: {
                            Text(label(for: hour))
                                .font(.cinema(15, weight: .semibold))
                                .strikethrough(taken)
                                .foregroundStyle(taken ? Theme.textTertiary : (slot == hour ? Color.white : Theme.textPrimary))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(slot == hour ? Theme.red : Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(taken)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(service.needsAddress ? "Property" : "Details")
                        .font(.cinema(17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if service.needsAddress {
                        TextField("Property address", text: $address)
                            .textContentType(.fullStreetAddress)
                            .inputStyle()
                    }
                    TextField("Access notes, talking points, MLS link", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .inputStyle()
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Deposit due today")
                        Spacer()
                        Text("$500").fontWeight(.bold)
                    }
                    .font(.cinema(16))
                    .foregroundStyle(Theme.textPrimary)
                    Text("Reschedule free up to 48 hours before. Cancellations inside 48 hours keep the deposit.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                Button {
                    guard let date = chosenDate else { return }
                    isPaying = true
                    Task {
                        confirmed = await store.payDepositAndBook(service: service, date: date, address: address, notes: notes)
                        isPaying = false
                    }
                } label: {
                    if isPaying {
                        ProgressView().tint(.white)
                    } else {
                        Label("Pay $500 deposit", systemImage: "creditcard.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canPay)
                .opacity(canPay ? 1 : 0.5)
            }
            .padding(Theme.gutter)
        }
    }

    private func confirmation(_ booking: Booking) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.red)
            Text("You're booked")
                .font(.cinema(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(booking.service.name)\n\(booking.date.shortDay) at \(booking.date.timeOnly)")
                .font(.cinema(16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
            Text("We'll send a prep checklist the day before. Your footage lands in your Library.")
                .font(.cinema(14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 24)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Theme.gutter)
        }
    }

    private func label(for hour: Int) -> String {
        let suffix = hour >= 12 ? "PM" : "AM"
        let display = hour > 12 ? hour - 12 : hour
        return "\(display):00 \(suffix)"
    }
}
