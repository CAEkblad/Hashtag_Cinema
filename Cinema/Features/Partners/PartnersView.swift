import SwiftUI

/// A vetted local service #Cinema agents can book or send clients to.
struct ServicePartner: Identifiable, Codable, Hashable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case staging, cleaning, moving, junk, handyman, painting, landscaping, pool, pressureWash, inspection, lending, title, insurance, transactionCoordinator, assistant, signs, gifts

        var id: String { rawValue }

        var title: String {
            switch self {
            case .staging: return "Staging"
            case .cleaning: return "Cleaning"
            case .moving: return "Movers"
            case .junk: return "Junk removal"
            case .handyman: return "Handyman"
            case .painting: return "Painting"
            case .landscaping: return "Lawn and curb appeal"
            case .pool: return "Pool service"
            case .pressureWash: return "Pressure washing"
            case .inspection: return "Inspections"
            case .lending: return "Lending"
            case .title: return "Title"
            case .insurance: return "Insurance"
            case .transactionCoordinator: return "Transaction coordinator"
            case .assistant: return "Virtual assistant"
            case .signs: return "Signs and install"
            case .gifts: return "Closing gifts"
            }
        }

        var icon: String {
            switch self {
            case .staging: return "sofa.fill"
            case .cleaning: return "sparkles"
            case .moving: return "shippingbox.fill"
            case .junk: return "trash.fill"
            case .handyman: return "hammer.fill"
            case .painting: return "paintbrush.fill"
            case .landscaping: return "leaf.fill"
            case .pool: return "drop.fill"
            case .pressureWash: return "water.waves"
            case .inspection: return "magnifyingglass.circle.fill"
            case .lending: return "banknote.fill"
            case .title: return "doc.text.fill"
            case .insurance: return "umbrella.fill"
            case .transactionCoordinator: return "list.clipboard.fill"
            case .assistant: return "person.crop.circle.badge.checkmark"
            case .signs: return "signpost.right.fill"
            case .gifts: return "gift.fill"
            }
        }

        /// Settlement services under RESPA: no referral fees, ever.
        var isSettlementService: Bool { [.lending, .title, .inspection, .insurance].contains(self) }

        var vendorCategory: Vendor.Category? {
            switch self {
            case .staging: return .stager
            case .cleaning: return .cleaner
            case .moving: return .movers
            case .handyman, .painting: return .handyman
            case .landscaping: return .landscaper
            case .pool: return .pool
            case .inspection: return .inspector
            case .lending: return .lender
            case .title: return .title
            case .insurance: return .insurance
            default: return nil
            }
        }
    }

    var id: String { company }
    var name: String
    var company: String
    var category: Category
    var cityName: String
    var rating: Double
    var jobs: Int
    var blurb: String
    var agentPerk: String
    var turnaround: String
}

enum PartnerDirectory {
    static func sample(city: String) -> [ServicePartner] {
        [
            ServicePartner(name: "Mia Castillo", company: "Shoreline Staging", category: .staging, cityName: city, rating: 4.9, jobs: 210, blurb: "Vacant and occupied staging, ready before your photo day.", agentPerk: "15% off for #Cinema agents", turnaround: "Install in 3 to 5 days"),
            ServicePartner(name: "Sparkle Team", company: "Sparkle Home Cleaning", category: .cleaning, cityName: city, rating: 4.8, jobs: 640, blurb: "Pre-listing, move out and post-construction cleans.", agentPerk: "$40 off pre-listing cleans", turnaround: "Next day"),
            ServicePartner(name: "Gator Moving", company: "Gator Moving Co.", category: .moving, cityName: city, rating: 4.7, jobs: 1_150, blurb: "Local and long distance, licensed and insured in Florida.", agentPerk: "Free boxes for your clients", turnaround: "Book 2 weeks out"),
            ServicePartner(name: "Haul Pros", company: "Haul Pros Junk Removal", category: .junk, cityName: city, rating: 4.8, jobs: 480, blurb: "Garage and estate cleanouts the same week.", agentPerk: "10% off estate cleanouts", turnaround: "Same week"),
            ServicePartner(name: "Frank Nolan", company: "Punch List Pros", category: .handyman, cityName: city, rating: 4.9, jobs: 390, blurb: "Inspection repairs and punch lists, with photos when done.", agentPerk: "Free estimate within 24 hours", turnaround: "2 to 4 days"),
            ServicePartner(name: "Fresh Coat", company: "Fresh Coat Painting", category: .painting, cityName: city, rating: 4.7, jobs: 260, blurb: "Interior refreshes in neutral, photo friendly colors.", agentPerk: "Listing refresh package", turnaround: "1 week"),
            ServicePartner(name: "Curb Ready", company: "Curb Ready Landscaping", category: .landscaping, cityName: city, rating: 4.8, jobs: 300, blurb: "Mulch, sod and trimming to make the front pop.", agentPerk: "Curb appeal package for listings", turnaround: "3 days"),
            ServicePartner(name: "Blue Water", company: "Blue Water Pools", category: .pool, cityName: city, rating: 4.9, jobs: 820, blurb: "Green to clean before the shoot.", agentPerk: "Pre-listing pool rescue", turnaround: "48 hours"),
            ServicePartner(name: "Pressure Perfect", company: "Pressure Perfect", category: .pressureWash, cityName: city, rating: 4.8, jobs: 510, blurb: "Roofs, pavers, driveways and lanais.", agentPerk: "Bundle with the pool clean", turnaround: "This week"),
            ServicePartner(name: "Mike Dawson", company: "Gulf Coast Inspections", category: .inspection, cityName: city, rating: 4.9, jobs: 2_300, blurb: "Full inspections plus wind mitigation and 4 point.", agentPerk: "Reports in 24 hours", turnaround: "Within 48 hours"),
            ServicePartner(name: "Rachel Kim", company: "Bayside Home Loans", category: .lending, cityName: city, rating: 4.9, jobs: 940, blurb: "Fast preapprovals, FHA, VA and first time buyer programs.", agentPerk: "Same day preapprovals", turnaround: "Same day"),
            ServicePartner(name: "Sunshine Title", company: "Sunshine Title and Escrow", category: .title, cityName: city, rating: 4.8, jobs: 3_100, blurb: "Mobile closings and clear communication.", agentPerk: "Weekly status updates", turnaround: "On your timeline"),
            ServicePartner(name: "Coastal Coverage", company: "Coastal Coverage Insurance", category: .insurance, cityName: city, rating: 4.6, jobs: 700, blurb: "Florida homeowners, flood and wind quotes from several carriers.", agentPerk: "Quotes in 24 hours", turnaround: "24 hours"),
            ServicePartner(name: "CloseDesk", company: "CloseDesk TC", category: .transactionCoordinator, cityName: "Remote", rating: 4.9, jobs: 1_800, blurb: "Contract to close coordination so you can sell.", agentPerk: "First file 50% off", turnaround: "Starts in 1 day"),
            ServicePartner(name: "Ava Assist", company: "Ava Virtual Assistants", category: .assistant, cityName: "Remote", rating: 4.7, jobs: 420, blurb: "CRM cleanup, social scheduling and lead follow up.", agentPerk: "First week free", turnaround: "Starts this week"),
            ServicePartner(name: "Post It", company: "Post It Sign Install", category: .signs, cityName: city, rating: 4.8, jobs: 1_400, blurb: "Sign posts, riders and lockboxes installed and picked up.", agentPerk: "Free rider with install", turnaround: "Next business day"),
            ServicePartner(name: "Gifted", company: "Gifted Closing Gifts", category: .gifts, cityName: "Ships anywhere", rating: 4.9, jobs: 2_600, blurb: "Branded closing gifts shipped to the new home.", agentPerk: "Free engraving with your logo", turnaround: "Ships in 3 days")
        ]
    }
}

struct PartnersView: View {
    @Environment(CinemaStore.self) private var store
    @State private var category: ServicePartner.Category?
    @State private var requesting: ServicePartner?

    private var partners: [ServicePartner] {
        PartnerDirectory.sample(city: store.homeCity.name).filter { category == nil || $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Partners")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Vetted pros for everything around a sale: staging, cleaning, movers, repairs, transaction coordinators and more. Book for yourself or send your client.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                NavigationLink(value: Route.findShooter) {
                    IconRow(icon: "camera.fill", title: "Photographers and video", subtitle: "#Cinema Crew near \(store.homeCity.name)")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("All", icon: "square.grid.2x2.fill", isOn: category == nil) { category = nil }
                        ForEach(ServicePartner.Category.allCases) { option in
                            chip(option.title, icon: option.icon, isOn: category == option) { category = option }
                        }
                    }
                }

                ForEach(partners) { partner in
                    partnerCard(partner)
                }

                Text("#Cinema never pays or takes referral fees for lenders, title, inspectors or insurance (RESPA settlement services). Perks are discounts partners offer agents directly. Sample partners until the directory is live.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)

                Link(destination: URL(string: "https://hashtagcinema.com/partners")!) {
                    Label("Know a great pro? Invite them to apply", systemImage: "person.badge.plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Partners")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $requesting) { partner in
            PartnerRequestView(partner: partner)
        }
    }

    private func partnerCard(_ partner: ServicePartner) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: partner.category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.red)
                    .frame(width: 44, height: 44)
                    .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.company)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(partner.category.title) · \(partner.cityName)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                    Label("\(String(format: "%.1f", partner.rating)) · \(partner.jobs.formatted()) jobs · \(partner.turnaround)", systemImage: "star.fill")
                        .font(.cinema(11, weight: .semibold))
                        .foregroundStyle(Theme.warning)
                }
                Spacer()
            }
            Text(partner.blurb)
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            Label(partner.agentPerk, systemImage: "tag.fill")
                .font(.cinema(12, weight: .semibold))
                .foregroundStyle(Theme.success)
            HStack(spacing: 10) {
                Button {
                    requesting = partner
                } label: {
                    Label("Request", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(PrimaryButtonStyle())
                if partner.category.vendorCategory != nil {
                    Button {
                        store.addPartnerToPros(partner)
                    } label: {
                        Label(store.hasPartnerInPros(partner) ? "In my pros" : "Save to my pros", systemImage: store.hasPartnerInPros(partner) ? "star.fill" : "star")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(store.hasPartnerInPros(partner))
                }
            }
        }
        .cardStyle()
    }

    private func chip(_ title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? .white : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PartnerRequestView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let partner: ServicePartner
    @State private var forClient = true
    @State private var clientName = ""
    @State private var address = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("This is for", selection: $forClient) {
                        Text("My client").tag(true)
                        Text("Me").tag(false)
                    }
                    .pickerStyle(.segmented)
                    if forClient {
                        TextField("Client name", text: $clientName)
                    }
                    TextField("Property address", text: $address)
                        .textContentType(.fullStreetAddress)
                    DatePicker("Ideal date", selection: $date, in: Date()..., displayedComponents: .date)
                    TextField("What do you need?", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                } footer: {
                    Text("\(partner.company) replies through #Cinema, usually within a few hours.")
                }
            }
            .navigationTitle(partner.category.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        store.requestPartner(partner, client: forClient ? clientName : nil, address: address, date: date, notes: notes)
                        dismiss()
                    }
                    .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
