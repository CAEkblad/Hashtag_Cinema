import SwiftUI

struct BookingView: View {
    @Environment(CinemaStore.self) private var store
    @State private var selectedService: ServiceType?
    @State private var rating: Booking?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Book a pro shoot")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("#Cinema Crew near \(store.homeCity.name). Listing packages from $179. A $500 deposit holds bigger shoots, the balance is charged on delivery.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                NavigationLink(value: Route.findShooter) {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Theme.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Find a photographer")
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(store.shooters(near: store.homeCity).count) vetted shooters near you, with ratings and portfolios")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.packageAdvisor) {
                    IconRow(icon: "wand.and.stars", title: "Not sure what to book?", subtitle: "Answer 4 quick questions and we'll pick the package")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.sellerPrep) {
                    IconRow(icon: "checklist", title: "Seller prep checklist", subtitle: "Send it to your seller before the shoot")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                ForEach(store.bookingsToRate) { booking in
                    Button {
                        rating = booking
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "star.bubble.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.warning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate your shoot at \(booking.address.isEmpty ? "the studio" : booking.address)")
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Text("Ratings help great shooters level up")
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer(minLength: 0)
                            StarRow(rating: 0, size: 12)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
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
                        NavigationLink(value: Route.bookingChat(booking.id)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(booking.packageName ?? booking.service.name)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(booking.date.shortDay) at \(booking.date.timeOnly)")
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                                if let shooter = booking.shooterID.flatMap({ store.shooter($0) }) {
                                    Text("Requested \(shooter.name)")
                                        .font(.cinema(12))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                if let stars = booking.rating {
                                    StarRow(rating: stars, size: 11)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Pill(text: booking.status.title, icon: "checkmark.seal.fill")
                                Label(store.unreadShootMessages(booking.id) > 0 ? "\(store.unreadShootMessages(booking.id)) new" : "Message", systemImage: "bubble.left.and.bubble.right.fill")
                                    .font(.cinema(12, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                            }
                        }
                        .cardStyle()
                        }
                        .buttonStyle(.plain)
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
        .sheet(item: $rating) { booking in
            RateShootView(booking: booking)
                .presentationDetents([.medium, .large])
        }
    }
}

struct RateShootView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let booking: Booking
    @State private var stars = 5
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("How was your shoot?")
                    .font(.cinema(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(booking.packageName ?? booking.service.name)
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            stars = value
                        } label: {
                            Image(systemName: value <= stars ? "star.fill" : "star")
                                .font(.system(size: 34))
                                .foregroundStyle(value <= stars ? Theme.warning : Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(value) stars")
                    }
                }
                .frame(maxWidth: .infinity)
                TextField(stars >= 4 ? "What did they do great?" : "What should we fix?", text: $comment, axis: .vertical)
                    .lineLimit(3...6)
                    .inputStyle()
                if stars <= 3 {
                    Text("Sorry it wasn't perfect. #Cinema will reach out about a free reshoot or edit.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.red)
                }
                Spacer()
                Button("Send rating") {
                    store.rate(booking.id, stars: stars, comment: comment)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.gutter)
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
            }
        }
    }
}

struct BookingFormView: View {
    let service: ServiceType
    var preferredShooter: Shooter? = nil
    var presetPackageID: String? = nil
    var presetAddOnIDs: Set<String> = []

    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var day = Calendar.current.startOfDay(for: Date().addingTimeInterval(60 * 60 * 24))
    @State private var slot: Int?
    @State private var address = ""
    @State private var notes = ""
    @State private var isPaying = false
    @State private var confirmed: Booking?
    @State private var package: ShootPackage? = ShootPackage.listing.first { $0.id == "full" }
    @State private var addOnIDs: Set<String> = []
    @State private var stagedPhotos = 5
    @State private var shooterID: UUID?
    @State private var didSetShooter = false

    private var usesPackages: Bool { service == .listing || service == .drone }
    private var chosenAddOns: [ShootAddOn] { ShootAddOn.all.filter { addOnIDs.contains($0.id) } }
    private var estimatedTotal: Int? {
        guard usesPackages, let package else { return nil }
        return package.price + chosenAddOns.reduce(0) { $0 + $1.price * ($1.perPhoto ? stagedPhotos : 1) }
    }
    private var dueToday: Int { min(500, estimatedTotal ?? 500) }
    private var chosenShooter: Shooter? { shooterID.flatMap { store.shooter($0) } }

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
            .onAppear {
                if !didSetShooter {
                    shooterID = preferredShooter?.id
                    if let presetPackageID, let preset = ShootPackage.listing.first(where: { $0.id == presetPackageID }) {
                        package = preset
                    }
                    if !presetAddOnIDs.isEmpty { addOnIDs = presetAddOnIDs }
                    didSetShooter = true
                }
            }
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
                if usesPackages { packagePicker }
                shooterPicker

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
                    if let estimatedTotal {
                        HStack {
                            Text("Estimated total")
                            Spacer()
                            Text("$\(estimatedTotal.formatted())")
                        }
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textSecondary)
                    }
                    HStack {
                        Text(dueToday < 500 ? "Due today" : "Deposit due today")
                        Spacer()
                        Text("$\(dueToday.formatted())").fontWeight(.bold)
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
                        confirmed = await store.payDepositAndBook(
                            service: service, date: date, address: address, notes: notes,
                            shooter: chosenShooter,
                            package: usesPackages ? package : nil,
                            addOns: usesPackages ? chosenAddOns : [],
                            stagedPhotos: stagedPhotos
                        )
                        isPaying = false
                    }
                } label: {
                    if isPaying {
                        ProgressView().tint(.white)
                    } else {
                        Label(dueToday < 500 ? "Pay $\(dueToday) and book" : "Pay $500 deposit", systemImage: "creditcard.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canPay)
                .opacity(canPay ? 1 : 0.5)
            }
            .padding(Theme.gutter)
        }
    }

    private var packagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick a package")
                .font(.cinema(17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            ForEach(ShootPackage.listing) { option in
                Button {
                    package = option
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: package == option ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(package == option ? Theme.red : Theme.textTertiary)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(option.name)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                if option.isLuxury {
                                    Pill(text: "Luxury", icon: "diamond.fill", color: Theme.ink, textColor: .white)
                                }
                            }
                            Text(option.includes.joined(separator: " · "))
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        Text(option.priceLabel)
                            .font(.cinema(15, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .cardStyle(padding: 12)
                    .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).stroke(package == option ? Theme.red : .clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }

            Text("Add ons")
                .font(.cinema(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 4)
            VStack(spacing: 0) {
                ForEach(ShootAddOn.all) { addOn in
                    Toggle(isOn: Binding(
                        get: { addOnIDs.contains(addOn.id) },
                        set: { on in if on { addOnIDs.insert(addOn.id) } else { addOnIDs.remove(addOn.id) } }
                    )) {
                        HStack {
                            Text(addOn.name)
                                .font(.cinema(14, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(addOn.priceLabel)
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .tint(Theme.red)
                    .padding(.vertical, 6)
                    if addOn.perPhoto && addOnIDs.contains(addOn.id) {
                        Stepper("\(stagedPhotos) photos to stage", value: $stagedPhotos, in: 1...40)
                            .font(.cinema(13))
                            .padding(.leading, 8)
                    }
                }
            }
            .cardStyle(padding: 12)
        }
    }

    private var shooterPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shooter")
                .font(.cinema(17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    shooterChip(nil)
                    ForEach(store.shooters(near: store.homeCity, skill: nil).prefix(8)) { shooter in
                        shooterChip(shooter)
                    }
                }
            }
            Text(chosenShooter == nil ? "We'll match the best available Crew shooter for your date." : "We'll ask \(chosenShooter?.name ?? "") first. If they're booked we match a shooter at the same tier or higher.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func shooterChip(_ shooter: Shooter?) -> some View {
        let isOn = shooterID == shooter?.id
        return Button {
            shooterID = shooter?.id
        } label: {
            VStack(spacing: 6) {
                if let shooter {
                    Avatar(initials: shooter.initials, size: 44, paletteIndex: shooter.tier.paletteIndex)
                    Text(shooter.name.split(separator: " ").first.map { String($0) } ?? shooter.name)
                        .font(.cinema(12, weight: .semibold))
                    Text("\(shooter.tier.title) · \(shooter.ratingLabel)")
                        .font(.cinema(10))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .frame(width: 44, height: 44)
                        .background(Theme.redSoft, in: Circle())
                    Text("Best match")
                        .font(.cinema(12, weight: .semibold))
                    Text("Any tier")
                        .font(.cinema(10))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(width: 92)
            .padding(.vertical, 10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isOn ? Theme.red : Theme.stroke, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.plain)
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
