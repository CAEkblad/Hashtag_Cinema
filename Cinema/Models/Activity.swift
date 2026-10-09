import Foundation

/// One line in the activity inbox: edits ready, new leads, bookings, approvals.
struct ActivityItem: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case edit, lead, booking, office, rating, referral, coach, system

        var icon: String {
            switch self {
            case .edit: return "wand.and.stars"
            case .lead: return "person.badge.plus"
            case .booking: return "camera.fill"
            case .office: return "building.2.fill"
            case .rating: return "star.fill"
            case .referral: return "gift.fill"
            case .coach: return "graduationcap.fill"
            case .system: return "bell.fill"
            }
        }
    }

    var id = UUID()
    var kind: Kind
    var title: String
    var detail: String
    var date: Date
    var route: Route?
    var isRead = false
}

struct Referral: Identifiable, Hashable {
    enum Status: String, Hashable {
        case invited, joined, rewarded

        var title: String {
            switch self {
            case .invited: return "Invited"
            case .joined: return "Joined"
            case .rewarded: return "2 credits earned"
            }
        }
    }

    var id = UUID()
    var name: String
    var date: Date
    var status: Status
}

/// Inputs for the script writer.
enum ScriptType: String, CaseIterable, Identifiable {
    case marketUpdate, listingTour, mythBuster, neighborhood, clientStory, recruiting, aboutMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .marketUpdate: return "Market update"
        case .listingTour: return "Listing tour"
        case .mythBuster: return "Myth buster"
        case .neighborhood: return "Neighborhood"
        case .clientStory: return "Client story"
        case .recruiting: return "Recruiting"
        case .aboutMe: return "About me"
        }
    }

    var category: IdeaCategory {
        switch self {
        case .marketUpdate: return .marketUpdate
        case .listingTour: return .listingTour
        case .mythBuster: return .mythBuster
        case .neighborhood: return .neighborhood
        case .clientStory: return .clientStory
        case .recruiting, .aboutMe: return .dayInLife
        }
    }

    var placeholder: String {
        switch self {
        case .marketUpdate: return "What changed? e.g. more homes for sale, rates dipped"
        case .listingTour: return "The address or the best feature"
        case .mythBuster: return "The myth, e.g. you need 20% down"
        case .neighborhood: return "The neighborhood or street"
        case .clientStory: return "What happened, e.g. first time buyers beat 6 offers"
        case .recruiting: return "Why agents love your team"
        case .aboutMe: return "Why you became an agent"
        }
    }
}
