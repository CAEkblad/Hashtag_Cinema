import SwiftUI
import UIKit

/// A digital business card: show the QR at an open house, or send the contact file.
struct BusinessCardView: View {
    @Environment(CinemaStore.self) private var store
    @State private var shareFile: ShareFile?
    @State private var showBigQR = false

    private var kit: BrandKit { store.brandKit }

    /// vCard text values escape backslashes, commas, semicolons and line breaks.
    private func esc(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private var vCard: String {
        let parts = store.profile.name.split(separator: " ")
        let first = parts.first.map(String.init) ?? store.profile.name
        let last = parts.dropFirst().joined(separator: " ")
        var lines = ["BEGIN:VCARD", "VERSION:3.0", "N:\(esc(last));\(esc(first));;;", "FN:\(esc(store.profile.name))"]
        let company = store.myMarketCenter?.name ?? store.profile.brokerage
        if !company.isEmpty { lines.append("ORG:\(esc(company))") }
        lines.append("TITLE:Real Estate Agent")
        if !kit.phone.isEmpty { lines.append("TEL;TYPE=CELL:\(kit.phone)") }
        if !store.profile.email.isEmpty { lines.append("EMAIL:\(store.profile.email)") }
        if !kit.website.isEmpty { lines.append("URL:\(kit.website.hasPrefix("http") ? kit.website : "https://\(kit.website)")") }
        lines.append("NOTE:\(esc(store.homeCity.name)) real estate")
        lines.append("END:VCARD")
        return lines.joined(separator: "\r\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                card

                Button {
                    showBigQR = true
                } label: {
                    Label("Show QR full screen", systemImage: "qrcode")
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack(spacing: 10) {
                    Button {
                        shareContact()
                    } label: {
                        Label("Send contact", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    ShareLink(item: textCard) {
                        Label("Text it", systemImage: "message.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if kit.phone.isEmpty || kit.website.isEmpty {
                    NavigationLink(value: Route.brandKit) {
                        IconRow(icon: "paintpalette.fill", title: "Finish your brand kit", subtitle: "Add your phone, website, headshot and logo to the card")
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }

                Text("People scan the code with their camera and save you straight to their contacts. No app needed.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Business card")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showBigQR) {
            VStack(spacing: 24) {
                Spacer()
                Text(store.profile.name)
                    .font(.cinema(28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                QRCodeView(text: vCard)
                    .frame(width: 280, height: 280)
                Text("Scan to save my contact")
                    .font(.cinema(17, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Button("Done") { showBigQR = false }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.ignoresSafeArea())
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                } else {
                    Avatar(initials: String(store.profile.name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased(), size: 64)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.profile.name)
                        .font(.cinema(22, weight: .heavy))
                    Text(store.myMarketCenter?.name ?? store.profile.brokerage)
                        .font(.cinema(13, weight: .semibold))
                        .opacity(0.85)
                }
                Spacer()
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    if !kit.phone.isEmpty { Label(kit.phone, systemImage: "phone.fill") }
                    if !store.profile.email.isEmpty { Label(store.profile.email, systemImage: "envelope.fill") }
                    if !kit.website.isEmpty { Label(kit.website, systemImage: "globe") }
                    Label(store.homeCity.displayName, systemImage: "mappin.and.ellipse")
                }
                .font(.cinema(13))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                Spacer()
                QRCodeView(text: vCard)
                    .frame(width: 92, height: 92)
                    .padding(6)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(kit.accent.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: kit.accent.opacity(0.3), radius: 16, y: 8)
    }

    private var textCard: String {
        var lines = [store.profile.name]
        let company = store.myMarketCenter?.name ?? store.profile.brokerage
        if !company.isEmpty { lines.append(company) }
        if !kit.phone.isEmpty { lines.append(kit.phone) }
        if !store.profile.email.isEmpty { lines.append(store.profile.email) }
        if !kit.website.isEmpty { lines.append(kit.website) }
        lines.append("Save my number for anything real estate in \(store.homeCity.name)!")
        return lines.joined(separator: "\n")
    }

    private func shareContact() {
        let fileName = store.profile.name.replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName.isEmpty ? "Contact" : fileName).vcf")
        try? vCard.write(to: url, atomically: true, encoding: .utf8)
        shareFile = ShareFile(url: url)
    }
}
