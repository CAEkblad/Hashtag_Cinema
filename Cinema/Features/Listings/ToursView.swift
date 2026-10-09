import SwiftUI

/// Plan showing days for buyers: stops in order, times, a route and a recap.
struct ToursView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showNew = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Showing tours")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Line up the homes, send your buyer the schedule and route, then send a recap of what they loved.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Button {
                    showNew = true
                } label: {
                    Label("Plan a tour", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                if store.tours.isEmpty {
                    Text("No tours yet. Plan one and add the homes you're showing.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .cardStyle()
                }

                ForEach(store.tours.sorted { $0.start < $1.start }) { tour in
                    NavigationLink(value: Route.tour(tour.id)) {
                        HStack(spacing: 12) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.red)
                                .frame(width: 40, height: 40)
                                .background(Theme.redSoft, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tour.buyerName)
                                    .font(.cinema(16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(tour.label) at \(tour.start.formatted(date: .omitted, time: .shortened)) · \(tour.stops.count) home\(tour.stops.count == 1 ? "" : "s")")
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Tours")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNew) {
            NewTourView()
        }
    }
}

struct NewTourView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var buyerName = ""
    @State private var start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date().addingTimeInterval(86_400)) ?? Date()
    @State private var minutes = 30

    var body: some View {
        NavigationStack {
            Form {
                TextField("Buyer's name", text: $buyerName)
                    .textContentType(.name)
                DatePicker("Starts", selection: $start, in: Date()...)
                Stepper("\(minutes) minutes per home", value: $minutes, in: 15...60, step: 5)
            }
            .navigationTitle("Plan a tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createTour(buyerName: buyerName.trimmingCharacters(in: .whitespaces), start: start, minutesPerStop: minutes)
                        dismiss()
                    }
                    .disabled(buyerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct TourDetailView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tourID: UUID

    @State private var address = ""
    @State private var price = ""
    @State private var showMileage = false

    var body: some View {
        if let tour = store.tour(tourID) {
            content(tour)
        } else {
            EmptyStateView(title: "Tour not found", message: "It may have been removed.", icon: "car")
                .cinemaScreen()
        }
    }

    private func content(_ tour: ShowingTour) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tour.buyerName)
                        .font(.cinema(22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(tour.label) · starts \(tour.start.formatted(date: .omitted, time: .shortened)) · \(tour.minutesPerStop) min per home")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.surface)

            Section {
                ForEach(Array(tour.stops.enumerated()), id: \.element.id) { index, stop in
                    HStack(spacing: 12) {
                        Text(tour.time(for: index).formatted(date: .omitted, time: .shortened))
                            .font(.cinema(12, weight: .bold))
                            .foregroundStyle(Theme.red)
                            .frame(width: 64, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.address)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            if !stop.price.isEmpty {
                                Text(stop.price)
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                        Menu {
                            ForEach(TourStop.Reaction.allCases, id: \.self) { reaction in
                                Button {
                                    store.setReaction(reaction, stopID: stop.id, tourID: tour.id)
                                } label: {
                                    Label(reaction.title, systemImage: reaction.icon)
                                }
                            }
                        } label: {
                            Image(systemName: stop.reaction?.icon ?? "face.smiling")
                                .foregroundStyle(stop.reaction == .love ? Theme.red : Theme.textSecondary)
                                .frame(width: 34, height: 34)
                        }
                        .accessibilityLabel("How did they like it?")
                    }
                }
                .onMove { store.moveStops(in: tour.id, from: $0, to: $1) }
                .onDelete { store.deleteStops(in: tour.id, at: $0) }
            } header: {
                Text("Homes, in driving order")
            } footer: {
                Text("Tap Edit to drag homes into order. After each showing, tap the face to log how your buyer felt.")
            }
            .listRowBackground(Theme.surface)

            Section("Add a home") {
                TextField("Address", text: $address)
                    .textContentType(.fullStreetAddress)
                TextField("Price (optional)", text: $price)
                Button("Add to tour") {
                    store.addStop(TourStop(address: address.trimmingCharacters(in: .whitespaces), price: price), to: tour.id)
                    address = ""
                    price = ""
                }
                .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
                let mine = store.listings.filter { listing in listing.status == .active && !tour.stops.contains { $0.address.hasPrefix(listing.address) } }
                ForEach(mine) { listing in
                    Button {
                        store.addStop(TourStop(address: "\(listing.address), \(listing.city?.name ?? "")", price: listing.priceLabel), to: tour.id)
                    } label: {
                        Label("Add my listing: \(listing.address)", systemImage: "house.fill")
                    }
                }
            }
            .listRowBackground(Theme.surface)

            Section("Send") {
                ShareLink(item: TourCopy.itinerary(tour, agentName: store.profile.name)) {
                    Label("Send schedule to \(tour.firstName)", systemImage: "paperplane.fill")
                }
                .disabled(tour.stops.isEmpty)
                if let url = tour.routeURL {
                    Link(destination: url) {
                        Label("Open the route in Maps", systemImage: "map.fill")
                    }
                }
                ShareLink(item: TourCopy.recap(tour, agentName: store.profile.name)) {
                    Label("Send the recap", systemImage: "heart.text.square.fill")
                }
                .disabled(!tour.stops.contains { $0.reaction != nil })
                Button {
                    showMileage = true
                } label: {
                    Label("Log the miles for this tour", systemImage: "car.fill")
                }
            }
            .listRowBackground(Theme.surface)

            Section {
                Button("Delete tour", role: .destructive) {
                    store.deleteTour(tour.id)
                    dismiss()
                }
            }
            .listRowBackground(Theme.surface)
        }
        .cinemaScreen()
        .navigationTitle("Tour")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showMileage) {
            AddExpenseView(presetNote: "Showings with \(tour.buyerName)")
        }
    }
}
