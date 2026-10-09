import SwiftUI

/// A message thread with the shooter for one booking. Phone numbers stay private,
/// so every detail about the shoot lives here.
struct ShootMessage: Identifiable, Hashable, Codable {
    var id = UUID()
    var bookingID: UUID
    var fromAgent: Bool
    var text: String
    var date: Date
    var isRead = true
}

struct BookingChatView: View {
    @Environment(CinemaStore.self) private var store
    let bookingID: UUID
    @State private var draft = ""

    private let quickReplies = [
        "Lockbox code is in the notes",
        "Seller will be home",
        "Please get the pool and lanai at sunset",
        "Can you add a few shots of the neighborhood?",
        "Running 10 minutes late"
    ]

    var body: some View {
        if let booking = store.bookings.first(where: { $0.id == bookingID }) {
            content(booking)
        } else {
            EmptyStateView(title: "Booking not found", message: "It may have been canceled.", icon: "calendar")
                .cinemaScreen()
        }
    }

    private func content(_ booking: Booking) -> some View {
        let shooter = booking.shooterID.flatMap { store.shooter($0) }
        let messages = store.shootMessages(for: booking.id)
        return VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(booking.packageName ?? booking.service.name)
                                .font(.cinema(17, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(booking.date.shortDay) at \(booking.date.timeOnly)\(booking.address.isEmpty ? "" : " · \(booking.address)")")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                            Text(shooter.map { "Chatting with \($0.name)" } ?? "Chatting with the #Cinema shoots team")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()

                        if messages.isEmpty {
                            Text("Send access details, must-get shots or anything the shooter should know.")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.vertical, 8)
                        }

                        ForEach(messages) { message in
                            bubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(Theme.gutter)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            VStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickReplies, id: \.self) { reply in
                            Button(reply) {
                                store.sendShootMessage(reply, bookingID: booking.id)
                            }
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.surfaceRaised, in: Capsule())
                        }
                    }
                    .padding(.horizontal, Theme.gutter)
                }
                HStack(spacing: 10) {
                    TextField("Message", text: $draft, axis: .vertical)
                        .lineLimit(1...4)
                        .inputStyle()
                    Button {
                        store.sendShootMessage(draft, bookingID: booking.id)
                        draft = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textTertiary : Theme.red)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Send")
                }
                .padding(.horizontal, Theme.gutter)
            }
            .padding(.vertical, 10)
            .background(Theme.surface)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(shooter?.name ?? "Shoot chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markShootMessagesRead(booking.id) }
        .onChange(of: messages.count) { store.markShootMessagesRead(booking.id) }
    }

    private func bubble(_ message: ShootMessage) -> some View {
        HStack {
            if message.fromAgent { Spacer(minLength: 50) }
            VStack(alignment: message.fromAgent ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.cinema(14))
                    .foregroundStyle(message.fromAgent ? .white : Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.fromAgent ? Theme.red : Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(message.date.formatted(date: .omitted, time: .shortened))
                    .font(.cinema(10))
                    .foregroundStyle(Theme.textTertiary)
            }
            if !message.fromAgent { Spacer(minLength: 50) }
        }
    }
}
