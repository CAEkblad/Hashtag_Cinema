import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Bring in photos an agent already has: from the MLS by listing number,
/// from the Photos app, or from Files (a photographer's download).
/// With no listing, an MLS import creates the listing too.
struct ListingPhotosView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID?

    enum Source: String, CaseIterable, Identifiable {
        case mls = "MLS number"
        case library = "Photos"
        case files = "Files"
        var id: String { rawValue }
    }

    @State private var source: Source = .mls
    @State private var mlsNumber = ""
    @State private var results: [MLSListing] = []
    @State private var selected: MLSListing?
    @State private var chosen: [URL] = []
    @State private var updateDetails = true
    @State private var isWorking = false
    @State private var progress: Double = 0
    @State private var errorText: String?
    @State private var saved: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showFiles = false
    @State private var createdID: UUID?
    @State private var askReplace: MLSListing?
    @State private var nearMatches = false

    private var listing: Listing? { listingID.flatMap { store.listing($0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(listingID == nil ? "Import a listing" : "Listing photos")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(listingID == nil ? "Type the MLS number and we'll pull in the details and every photo, ready for reels, posters and flyers." : "Already have photos? Pull them from the MLS, your Photos app or Files, then make reels, posters and flyers from them.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                if listingID != nil {
                    Picker("From", selection: $source) {
                        ForEach(Source.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                if let createdID {
                    created(createdID)
                } else {
                    switch source {
                    case .mls: mlsSection
                    case .library: librarySection
                    case .files: filesSection
                    }
                }

                if !saved.isEmpty {
                    savedSection
                }

                if let errorText {
                    Label(errorText, systemImage: "exclamationmark.triangle.fill")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle(listingID == nil ? "Import listing" : "Photos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let listingID, saved.isEmpty { saved = ListingPhotoStore.thumbnails(listingID) }
            if mlsNumber.isEmpty, let number = listing?.mlsNumber { mlsNumber = number }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importLibrary(items) }
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { Task { await importFiles(urls) } }
        }
        .confirmationDialog("This listing already has \(saved.count) photo\(saved.count == 1 ? "" : "s")", isPresented: Binding(get: { askReplace != nil }, set: { if !$0 { askReplace = nil } }), titleVisibility: .visible, presenting: askReplace) { item in
            Button("Replace them with the MLS photos", role: .destructive) { Task { await importMLS(item, replace: true) } }
            Button("Add the MLS photos after them") { Task { await importMLS(item, replace: false) } }
        }
    }

    // MARK: MLS

    private var mlsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField("MLS number", text: $mlsNumber)
                    .inputStyle()
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await find() } }
                Button("Find") { Task { await find() } }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .disabled(mlsNumber.trimmingCharacters(in: .whitespaces).isEmpty || isWorking)
            }

            if MLSService.isTestFeed {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Test MLS", systemImage: "testtube.2")
                        .font(.cinema(13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("This build reads a public sample MLS feed so you can try the import with real photos. Your Stellar MLS listings connect once the data feed is approved for your brokerage.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                    Button("Show sample listings") { Task { await loadSamples() } }
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .disabled(isWorking)
                }
                .cardStyle()
            }

            if isWorking && selected == nil {
                ProgressView().frame(maxWidth: .infinity)
            }

            if let selected {
                selectedCard(selected)
            } else if !results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(nearMatches ? "Close matches" : "Sample listings")
                        .font(.cinema(15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    ForEach(results) { item in
                        Button { pick(item) } label: { resultRow(item) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func resultRow(_ item: MLSListing) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.photoURLs.first) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Theme.surfaceRaised
            }
            .frame(width: 72, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.address)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(item.priceLabel) · \(item.specs)")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
                Text("MLS \(item.mlsNumber) · \(item.photoURLs.count) photos")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 10)
    }

    private func selectedCard(_ item: MLSListing) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.address)
                        .font(.cinema(17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text([item.place, item.postalCode].filter { !$0.isEmpty }.joined(separator: " "))
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(item.priceLabel) · \(item.specs)")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("MLS \(item.mlsNumber) · \(item.status)\(item.officeName.isEmpty ? "" : " · \(item.officeName)")")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Button {
                    selected = nil
                    chosen = []
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            if item.photoURLs.isEmpty {
                Text("This listing has no photos on the MLS yet.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                HStack {
                    Text("\(chosen.count) of \(item.photoURLs.count) photos selected")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button(chosen.count == item.photoURLs.count ? "Select none" : "Select all") {
                        chosen = chosen.count == item.photoURLs.count ? [] : item.photoURLs
                    }
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    ForEach(item.photoURLs, id: \.self) { url in
                        Button { toggle(url) } label: { remoteTile(url, isOn: chosen.contains(url)) }
                            .buttonStyle(.plain)
                    }
                }
            }

            Toggle(listingID == nil ? "Use the MLS description" : "Also update price, beds, baths and description", isOn: $updateDetails)
                .font(.cinema(13, weight: .semibold))
                .tint(Theme.red)

            if isWorking {
                ProgressView(value: progress) { Text("Downloading photos").font(.cinema(12)) }
                    .tint(Theme.red)
            }

            Button {
                if listingID != nil && !saved.isEmpty && !chosen.isEmpty {
                    askReplace = item
                } else {
                    Task { await importMLS(item, replace: true) }
                }
            } label: {
                Label(listingID == nil ? "Add listing with \(chosen.count) photo\(chosen.count == 1 ? "" : "s")" : "Import \(chosen.count) photo\(chosen.count == 1 ? "" : "s")", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isWorking || (chosen.isEmpty && listingID != nil))
        }
        .cardStyle()
    }

    private func remoteTile(_ url: URL, isOn: Bool) -> some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Theme.surfaceRaised.overlay(ProgressView())
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: 84)
        .clipped()
        .overlay(alignment: .topTrailing) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isOn ? Theme.red : .white)
                .shadow(radius: 2)
                .padding(5)
        }
        .opacity(isOn ? 1 : 0.55)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: Photos and Files

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 40, matching: .images) {
                Label("Choose from Photos", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isWorking)
            Text("Pick up to 40. They're added after any photos already on this listing.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
            if isWorking { ProgressView().frame(maxWidth: .infinity) }
        }
    }

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showFiles = true } label: {
                Label("Choose from Files", systemImage: "folder.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isWorking)
            if isWorking { ProgressView().frame(maxWidth: .infinity) }
            Text("Got a download link from your photographer? Save the photos to Files, then pick them here. Dropbox and Google Drive work too.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(saved.count) photo\(saved.count == 1 ? "" : "s") on this listing")
                    .font(.cinema(15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let listingID {
                    Button("Remove all", role: .destructive) {
                        ListingPhotoStore.delete(listingID)
                        saved = []
                    }
                    .font(.cinema(13, weight: .semibold))
                    .disabled(isWorking)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(Array(saved.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            if let listingID {
                HStack(spacing: 10) {
                    NavigationLink(value: Route.listingReel(listingID)) {
                        Label("Reel", systemImage: "film.stack.fill").lineLimit(1).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    NavigationLink(value: Route.listingPoster(listingID)) {
                        Label("Poster", systemImage: "rectangle.portrait.fill").lineLimit(1).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .cardStyle()
    }

    private func created(_ id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Listing added", systemImage: "checkmark.circle.fill")
                .font(.cinema(17, weight: .bold))
                .foregroundStyle(Theme.success)
            Text("The photos are saved on the listing. Make a reel or poster from them now.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink(value: Route.listing(id)) {
                Label("Open the listing", systemImage: "house.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            HStack(spacing: 10) {
                NavigationLink(value: Route.listingReel(id)) {
                    Label("Reel", systemImage: "film.stack.fill").lineLimit(1).frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                NavigationLink(value: Route.listingPoster(id)) {
                    Label("Poster", systemImage: "rectangle.portrait.fill").lineLimit(1).frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
    }

    // MARK: Actions

    private func toggle(_ url: URL) {
        if let index = chosen.firstIndex(of: url) { chosen.remove(at: index) } else if let order = selected?.photoURLs {
            chosen.append(url)
            chosen.sort { (order.firstIndex(of: $0) ?? 0) < (order.firstIndex(of: $1) ?? 0) }
        }
    }

    private func pick(_ item: MLSListing) {
        selected = item
        chosen = item.photoURLs
        mlsNumber = item.mlsNumber
        errorText = nil
    }

    private func find() async {
        errorText = nil
        isWorking = true
        defer { isWorking = false }
        do {
            nearMatches = false
            pick(try await MLSService.listing(mlsNumber: mlsNumber))
        } catch {
            selected = nil
            let close = (try? await MLSService.search(mlsNumber, limit: 10)) ?? []
            results = close
            nearMatches = !close.isEmpty
            if close.isEmpty {
                errorText = error.localizedDescription + (MLSService.isTestFeed ? " Tap Show sample listings to try one from the test feed." : "")
            } else {
                errorText = "No listing has MLS number \(mlsNumber.trimmingCharacters(in: .whitespaces)). Here are close matches. Check the number before importing."
            }
        }
    }

    private func loadSamples() async {
        errorText = nil
        isWorking = true
        defer { isWorking = false }
        do {
            selected = nil
            nearMatches = false
            results = try await MLSService.search("", limit: 20)
            if results.isEmpty { errorText = "The sample feed didn't return any listings. Try again in a minute." }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func importMLS(_ item: MLSListing, replace: Bool) async {
        errorText = nil
        isWorking = true
        progress = 0
        defer { isWorking = false }
        let urls = chosen
        let images = await MLSService.downloadPhotos(urls) { value in progress = value }
        if !urls.isEmpty && images.isEmpty {
            errorText = "Couldn't download the photos. Check your connection and try again."
            return
        }
        let data = await Task.detached(priority: .userInitiated) { ListingPhotoStore.encode(images) }.value
        if let listingID, var current = store.listing(listingID) {
            current.mlsNumber = item.mlsNumber
            if updateDetails { apply(item, to: &current) }
            store.updateListing(current)
            if replace { ListingPhotoStore.replace(with: data, for: listingID) } else { ListingPhotoStore.append(data, for: listingID) }
            saved = ListingPhotoStore.thumbnails(listingID)
            store.persist()
            store.showToast("\(data.count) photo\(data.count == 1 ? "" : "s") imported from the MLS")
        } else {
            var new = Listing(address: item.address, cityID: cityID(for: item.city), price: item.price, beds: item.beds, baths: item.baths, squareFeet: item.squareFeet, status: status(for: item.status), features: item.hasPool ? [.pool] : [], listedAt: Calendar.current.date(byAdding: .day, value: -(item.daysOnMarket ?? 0), to: Date()) ?? Date())
            new.mlsNumber = item.mlsNumber
            if !FloridaMarkets.all.contains(where: { $0.name.caseInsensitiveCompare(item.city) == .orderedSame }) && !item.place.isEmpty {
                new.placeName = item.place
            }
            let added = store.addListing(new)
            if updateDetails && !item.remarks.isEmpty, var withRemarks = store.listing(added.id) {
                withRemarks.description = item.remarks
                store.updateListing(withRemarks)
            }
            ListingPhotoStore.replace(with: data, for: added.id)
            saved = ListingPhotoStore.thumbnails(added.id)
            store.persist()
            createdID = added.id
        }
    }

    private func apply(_ item: MLSListing, to listing: inout Listing) {
        if item.price > 0 { listing.price = item.price }
        if item.beds > 0 { listing.beds = item.beds }
        if item.baths > 0 { listing.baths = item.baths }
        if let sqft = item.squareFeet, sqft > 0 { listing.squareFeet = sqft }
        if !item.remarks.isEmpty { listing.description = item.remarks }
        if item.hasPool && !listing.features.contains(.pool) { listing.features.append(.pool) }
    }

    private func cityID(for name: String) -> String {
        FloridaMarkets.all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.id ?? store.homeCity.id
    }

    /// Off market statuses (hold, withdrawn, expired, cancelled) come in as coming
    /// soon so they never trigger "just listed" posters or buyer match alerts.
    private func status(for text: String) -> ListingStatus {
        let lower = text.lowercased()
        if lower.contains("coming") { return .comingSoon }
        if lower.contains("closed") || lower.contains("sold") { return .sold }
        if ["pending", "contract", "contingent", "backup"].contains(where: lower.contains) { return .underContract }
        if ["hold", "withdrawn", "expired", "cancel", "delete", "incomplete"].contains(where: lower.contains) { return .comingSoon }
        return .active
    }

    private func importLibrary(_ items: [PhotosPickerItem]) async {
        guard let listingID else { return }
        isWorking = true
        defer { isWorking = false }
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        pickerItems = []
        await add(loaded, to: listingID)
    }

    private func importFiles(_ urls: [URL]) async {
        guard let listingID else { return }
        isWorking = true
        defer { isWorking = false }
        // Read through a file coordinator so cloud files (iCloud, Dropbox, Drive) download first.
        let loaded: [UIImage] = await Task.detached(priority: .userInitiated) {
            var images: [UIImage] = []
            for url in urls {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                var readError: NSError?
                NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &readError) { readURL in
                    if let data = try? Data(contentsOf: readURL), let image = UIImage(data: data) { images.append(image) }
                }
            }
            return images
        }.value
        await add(loaded, to: listingID)
    }

    private func add(_ images: [UIImage], to listingID: UUID) async {
        guard !images.isEmpty else {
            store.showToast("Couldn't read those photos. Try saving them to your phone first.")
            return
        }
        let data = await Task.detached(priority: .userInitiated) { ListingPhotoStore.encode(images) }.value
        ListingPhotoStore.append(data, for: listingID)
        saved = ListingPhotoStore.thumbnails(listingID)
        store.showToast("\(data.count) photo\(data.count == 1 ? "" : "s") added")
    }
}
