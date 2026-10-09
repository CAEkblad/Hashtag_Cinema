import Foundation

/// Sample #Cinema Crew shooters until the backend directory is live.
extension MockData {
    private static func portfolio(_ items: [(String, String, Int, Bool)]) -> [PortfolioItem] {
        items.map { PortfolioItem(title: $0.0, symbol: $0.1, paletteIndex: $0.2, isVideo: $0.3) }
    }

    static let shooters: [Shooter] = [
        Shooter(
            name: "Marcus Bell", cityID: "tampa-hillsborough",
            bio: "Waterfront and luxury specialist. Flambient interiors, twilight exteriors and smooth drone reveals on Bayshore and Davis Islands.",
            skills: [.listingPhotos, .drone, .video, .twilight, .matterport],
            tier: .legend, rating: 4.97, jobsCompleted: 412, fiveStarCount: 371, yearsShooting: 9,
            responseTime: "Replies in about 10 min", nextOpening: day(1, hour: 9),
            portfolio: portfolio([("Davis Islands estate", "house.fill", 1, false), ("Bayshore twilight", "moon.stars.fill", 3, false), ("Harbour Island reveal", "airplane", 0, true), ("South Tampa pool home", "drop.fill", 4, false), ("Waterfront walkthrough", "video.fill", 2, true), ("Hyde Park bungalow", "house.lodge.fill", 5, false)]),
            reviews: [
                ShootReview(author: "Taylor B.", rating: 5, text: "Twilight shots sold the house. Showings doubled the first weekend.", date: day(-6)),
                ShootReview(author: "Jordan R.", rating: 5, text: "On time, fast delivery, and the drone reveal is my best performing reel.", date: day(-20))
            ],
            hasPart107: true, gear: "Sony full frame, DJI Mavic 3 Pro, gimbal"
        ),
        Shooter(
            name: "Alexis Moreno", cityID: "st-petersburg-pinellas",
            bio: "Bright, airy listing photos and vertical video built for Instagram. Loves condos and downtown St. Pete.",
            skills: [.listingPhotos, .video, .headshots, .brandVideo],
            tier: .elite, rating: 4.91, jobsCompleted: 168, fiveStarCount: 139, yearsShooting: 6,
            responseTime: "Replies in about 20 min", nextOpening: day(1, hour: 13),
            portfolio: portfolio([("Downtown condo", "building.2.fill", 1, false), ("Old Northeast", "house.fill", 4, false), ("Agent brand film", "person.crop.rectangle.fill", 0, true), ("Snell Isle", "sailboat.fill", 2, false)]),
            reviews: [ShootReview(author: "Chris N.", rating: 5, text: "My brand video finally feels like me. Booking again next month.", date: day(-11))]
        ),
        Shooter(
            name: "Devon Price", cityID: "brandon-hillsborough",
            bio: "Fast turnaround suburban listings across Brandon, Riverview and Valrico. Next day delivery is standard.",
            skills: [.listingPhotos, .drone, .matterport],
            tier: .pro, rating: 4.84, jobsCompleted: 61, fiveStarCount: 44, yearsShooting: 4,
            responseTime: "Replies in about 30 min", nextOpening: day(0, hour: 16),
            portfolio: portfolio([("Riverview new build", "hammer.fill", 5, false), ("Valrico pool home", "drop.fill", 1, false), ("Brandon drone", "airplane", 3, false)]),
            reviews: [ShootReview(author: "Morgan L.", rating: 5, text: "Got photos back the next morning, perfect for a Friday launch.", date: day(-3))],
            hasPart107: true
        ),
        Shooter(
            name: "Priya Shah", cityID: "wesley-chapel-pasco",
            bio: "New construction and master planned communities. Lifestyle B-roll of amenities that makes buyers want the neighborhood.",
            skills: [.listingPhotos, .video, .drone, .events],
            tier: .pro, rating: 4.79, jobsCompleted: 38, fiveStarCount: 27, yearsShooting: 3,
            responseTime: "Replies in about 1 hr", nextOpening: day(2, hour: 10),
            portfolio: portfolio([("Epperson lagoon", "water.waves", 1, true), ("Model home", "house.fill", 4, false), ("Community event", "party.popper.fill", 0, false)]),
            reviews: [],
            hasPart107: true
        ),
        Shooter(
            name: "Logan Carter", cityID: "sarasota-sarasota",
            bio: "Gulf front and Siesta Key specialist. Cinematic films for luxury listings.",
            skills: [.video, .drone, .twilight, .brandVideo],
            tier: .elite, rating: 4.93, jobsCompleted: 121, fiveStarCount: 104, yearsShooting: 8,
            responseTime: "Replies in about 15 min", nextOpening: day(3, hour: 9),
            portfolio: portfolio([("Siesta Key estate film", "film.fill", 3, true), ("Lido Key sunset", "sun.horizon.fill", 5, false), ("Bird Key dock", "sailboat.fill", 1, false)]),
            reviews: [ShootReview(author: "Sam P.", rating: 5, text: "The film looked like a TV show. Seller was blown away.", date: day(-9))],
            hasPart107: true
        ),
        Shooter(
            name: "Jasmine Reed", cityID: "clearwater-pinellas",
            bio: "Headshots and agent brand content in the studio or on the beach. Makes camera shy agents comfortable.",
            skills: [.headshots, .brandVideo, .podcast, .events],
            tier: .pro, rating: 4.88, jobsCompleted: 54, fiveStarCount: 46, yearsShooting: 5,
            responseTime: "Replies in about 45 min", nextOpening: day(1, hour: 10),
            portfolio: portfolio([("Team headshots", "person.3.fill", 4, false), ("Beach brand shoot", "beach.umbrella.fill", 2, false), ("Podcast set", "mic.fill", 0, true)]),
            reviews: []
        ),
        Shooter(
            name: "Tyler Brooks", cityID: "lakeland-polk",
            bio: "Value focused listing photos for Polk County with drone included on most shoots.",
            skills: [.listingPhotos, .drone],
            tier: .rookie, rating: 4.7, jobsCompleted: 12, fiveStarCount: 9, yearsShooting: 2,
            responseTime: "Replies in about 1 hr", nextOpening: day(0, hour: 13),
            portfolio: portfolio([("Lake Hollingsworth", "drop.fill", 1, false), ("Lakeland ranch", "tree.fill", 4, false)]),
            reviews: [],
            hasPart107: true
        ),
        Shooter(
            name: "Sofia Alvarez", cityID: "orlando-orange",
            bio: "Lake Nona to Winter Park. Short term rental listings near the parks are my specialty.",
            skills: [.listingPhotos, .video, .matterport, .twilight],
            tier: .elite, rating: 4.9, jobsCompleted: 133, fiveStarCount: 112, yearsShooting: 7,
            responseTime: "Replies in about 20 min", nextOpening: day(2, hour: 13),
            portfolio: portfolio([("Lake Nona home", "house.fill", 0, false), ("Vacation rental", "suitcase.rolling.fill", 5, false), ("Winter Park twilight", "moon.stars.fill", 3, false)]),
            reviews: [ShootReview(author: "Avery C.", rating: 5, text: "3D tour and photos the same day. My investor clients loved it.", date: day(-14))]
        ),
        Shooter(
            name: "Andre Santos", cityID: "miami-miami-dade",
            bio: "High rise condos and Brickell views. Bilingual, English and Spanish, on camera and off.",
            skills: [.listingPhotos, .video, .drone, .brandVideo],
            tier: .pro, rating: 4.82, jobsCompleted: 47, fiveStarCount: 35, yearsShooting: 5,
            responseTime: "Replies in about 30 min", nextOpening: day(1, hour: 16),
            portfolio: portfolio([("Brickell penthouse", "building.fill", 3, false), ("Bay views", "water.waves", 1, true)]),
            reviews: [],
            hasPart107: true
        ),
        Shooter(
            name: "Grace Whitfield", cityID: "jacksonville-duval",
            bio: "First Coast listings from Riverside to Ponte Vedra. Military families welcome, flexible PCS scheduling.",
            skills: [.listingPhotos, .drone, .headshots],
            tier: .rookie, rating: 4.75, jobsCompleted: 19, fiveStarCount: 14, yearsShooting: 2,
            responseTime: "Replies in about 1 hr", nextOpening: day(2, hour: 9),
            portfolio: portfolio([("Riverside bungalow", "house.lodge.fill", 2, false), ("Ponte Vedra golf", "figure.golf", 4, false)]),
            reviews: [],
            hasPart107: true
        )
    ]

    static let crewJobOffers: [CrewJobOffer] = [
        CrewJobOffer(title: "Full package listing", address: "4821 W Bayshore Blvd, Tampa", date: day(1, hour: 9), pay: 180, bonus: 10, skill: .listingPhotos),
        CrewJobOffer(title: "Drone add on", address: "211 Davis Blvd, Tampa", date: day(2, hour: 16), pay: 75, bonus: 10, skill: .drone),
        CrewJobOffer(title: "Agent brand video", address: "#Cinema studio", date: day(3, hour: 10), pay: 250, bonus: 10, skill: .brandVideo)
    ]
}
