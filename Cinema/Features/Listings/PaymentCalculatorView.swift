import SwiftUI
import UIKit

/// Monthly payment with Florida taxes and insurance. Share it as a graphic for social.
struct PaymentCalculatorView: View {
    @Environment(CinemaStore.self) private var store
    var startingPrice: Double = 450_000

    @State private var price: Double = 450_000
    @State private var downPercent: Double = 10
    @State private var rate: Double = 6.5
    @State private var years = 30
    @State private var taxRate: Double = 1.1
    @State private var insurance: Double = 4_200
    @State private var hoa: Double = 0
    @State private var didLoad = false
    @State private var shareImage: ShareBundle?

    struct ShareBundle: Identifiable {
        let id = UUID()
        let image: UIImage
        let caption: String
    }

    private var estimate: PaymentEstimate {
        PaymentEstimate(price: price, downPercent: downPercent, rate: rate, years: years, taxRate: taxRate, insuranceYearly: insurance, hoaMonthly: hoa)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PaymentCard(estimate: estimate, agentName: store.profile.name, cityName: store.homeCity.name)

                VStack(alignment: .leading, spacing: 14) {
                    slider("Price", value: $price, range: 100_000...5_000_000, step: 5_000, label: money(price))
                    slider("Down payment", value: $downPercent, range: 0...50, step: 0.5, label: "\(String(format: "%.1f", downPercent))% · \(money(price * downPercent / 100))")
                    slider("Interest rate", value: $rate, range: 2...10, step: 0.125, label: String(format: "%.3f%%", rate))
                    Picker("Term", selection: $years) {
                        Text("30 years").tag(30)
                        Text("20 years").tag(20)
                        Text("15 years").tag(15)
                    }
                    .pickerStyle(.segmented)
                    slider("Property tax rate", value: $taxRate, range: 0.5...2.5, step: 0.05, label: String(format: "%.2f%% a year", taxRate))
                    slider("Home insurance", value: $insurance, range: 0...20_000, step: 100, label: "\(money(insurance)) a year")
                    slider("HOA", value: $hoa, range: 0...1_500, step: 25, label: "\(money(hoa)) a month")
                }
                .cardStyle()

                Button {
                    share()
                } label: {
                    Label("Share as a graphic", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Estimates only, not a loan offer. Florida insurance varies a lot by location, roof age and flood zone. Have buyers get real quotes and talk to a lender.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Payment calculator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            price = startingPrice
        }
        .sheet(item: $shareImage) { bundle in
            ActivityView(items: [bundle.image, bundle.caption])
                .presentationDetents([.medium, .large])
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(label)
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
            Slider(value: value, in: range, step: step)
                .tint(Theme.red)
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    @MainActor
    private func share() {
        let card = PaymentCard(estimate: estimate, agentName: store.profile.name, cityName: store.homeCity.name)
            .frame(width: 360)
            .padding(16)
            .background(Theme.background)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        let caption = "What does a \(money(price)) home in \(store.homeCity.name) cost per month? About \(money(estimate.total)) with \(String(format: "%.0f", downPercent))% down at \(String(format: "%.2f", rate))%. Comment PAYMENT and I'll run your numbers. #floridarealestate"
        shareImage = ShareBundle(image: image, caption: caption)
    }
}

struct PaymentCard: View {
    let estimate: PaymentEstimate
    let agentName: String
    let cityName: String

    private let colors: [Color] = [Theme.red, Color(hex: 0x5B8DEF), Color(hex: 0xF5C04A), Color(hex: 0x4CC9A0), Color(hex: 0x9B8AE6)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Estimated monthly payment")
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(estimate.total.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(.cinema(40, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(estimate.price.formatted(.currency(code: "USD").precision(.fractionLength(0)))) home · \(String(format: "%.1f", estimate.downPercent))% down · \(estimate.years) years at \(String(format: "%.2f", estimate.rate))%")
                .font(.cinema(12))
                .foregroundStyle(Theme.textSecondary)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(Array(estimate.parts.enumerated()), id: \.offset) { index, part in
                        Rectangle()
                            .fill(colors[index % colors.count])
                            .frame(width: max(4, geo.size.width * part.1 / max(estimate.total, 1) - 2))
                    }
                }
            }
            .frame(height: 12)
            .clipShape(Capsule())

            VStack(spacing: 8) {
                ForEach(Array(estimate.parts.enumerated()), id: \.offset) { index, part in
                    HStack {
                        Circle().fill(colors[index % colors.count]).frame(width: 9, height: 9)
                        Text(part.0)
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(part.1.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }

            Divider()
            HStack {
                CinemaLogo(size: 14)
                Spacer()
                Text("\(agentName) · \(cityName)")
                    .font(.cinema(11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardStyle()
    }
}
