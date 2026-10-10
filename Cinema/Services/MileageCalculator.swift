import MapKit

/// Driving miles between addresses, from Apple Maps. No location permission needed.
enum MileageCalculator {
    enum Failure: LocalizedError {
        case notFound(String)
        case noRoute

        var errorDescription: String? {
            switch self {
            case .notFound(let address): return "Couldn't find \(address). Try adding the city."
            case .noRoute: return "Apple Maps couldn't find a driving route."
            }
        }
    }

    /// Miles driving through every address in order.
    @MainActor
    static func drivingMiles(through addresses: [String], near city: FloridaCity?) async throws -> Double {
        let stops = addresses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard stops.count >= 2 else { return 0 }
        var items: [MKMapItem] = []
        for address in stops {
            items.append(try await find(address, near: city))
        }
        var meters = 0.0
        for (from, to) in zip(items, items.dropFirst()) {
            let request = MKDirections.Request()
            request.source = from
            request.destination = to
            request.transportType = .automobile
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.min(by: { $0.distance < $1.distance }) else { throw Failure.noRoute }
            meters += route.distance
        }
        return meters / 1_609.344
    }

    @MainActor
    private static func find(_ address: String, near city: FloridaCity?) async throws -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        if let city {
            request.region = MKCoordinateRegion(center: city.coordinate, span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3))
        }
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else { throw Failure.notFound(address) }
        return item
    }
}

/// A drive the agent makes often, logged in one tap.
struct SavedTrip: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var miles: Double
}
