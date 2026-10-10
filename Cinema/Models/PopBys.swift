import Foundation

/// A small gift dropped at a client's door with a tag. Part of staying in touch.
struct PopByIdea: Identifiable, Hashable {
    var id: String { "\(month)-\(item)" }
    let month: Int
    let item: String
    let tag: String
    let cost: String
    let tip: String
}

enum PopByLibrary {
    static let all: [PopByIdea] = [
        PopByIdea(month: 1, item: "Lip balm", tag: "Wishing you a smooth new year!", cost: "About $2", tip: "Buy a multipack and tie the tag on with ribbon."),
        PopByIdea(month: 1, item: "Mini planner or calendar", tag: "Here's to the year you've been planning for.", cost: "About $4", tip: "Write your phone number on the inside cover."),
        PopByIdea(month: 2, item: "Chocolate bar", tag: "Sweet clients are the best clients.", cost: "About $2", tip: "Wrap the bar in a printed sleeve with your name."),
        PopByIdea(month: 2, item: "Conversation heart candy", tag: "You hold a special place in my business.", cost: "About $1", tip: "Small bags are cheaper by the dozen."),
        PopByIdea(month: 3, item: "Flower or herb seed packet", tag: "Thanks for helping my business grow!", cost: "About $1", tip: "Pick seeds that grow well in your area this spring."),
        PopByIdea(month: 3, item: "Chocolate gold coins", tag: "Lucky to have you as a client.", cost: "About $2", tip: "Great around St. Patrick's Day."),
        PopByIdea(month: 4, item: "Bubble wand", tag: "Just popping by to say thanks!", cost: "About $1", tip: "A hit with families that have kids."),
        PopByIdea(month: 4, item: "Small potted plant", tag: "Thanks for letting me help you plant roots here.", cost: "About $4", tip: "Succulents last and need almost no care."),
        PopByIdea(month: 5, item: "Lemonade mix", tag: "Thanks for making my business a little sweeter.", cost: "About $2", tip: "Single serve packets fit in a small bag with the tag."),
        PopByIdea(month: 5, item: "Mini succulent", tag: "Thank you for helping my business bloom.", cost: "About $3", tip: "Ask a local nursery for a bulk price."),
        PopByIdea(month: 6, item: "Flashlight", tag: "You light up my business! Here's to a safe storm season.", cost: "About $3", tip: "Add a one page hurricane prep checklist for Florida clients."),
        PopByIdea(month: 6, item: "Sunscreen", tag: "Have a sun-sational summer!", cost: "About $3", tip: "Travel size bottles keep the cost down."),
        PopByIdea(month: 7, item: "Microwave popcorn", tag: "Just popping by to say hi!", cost: "About $1", tip: "The classic pop by. Tie two bags together with the tag."),
        PopByIdea(month: 7, item: "Popsicle or freeze pop pack", tag: "Just chillin' and thinking of you.", cost: "About $2", tip: "Only on a cool day, or hand it over in person."),
        PopByIdea(month: 8, item: "School supplies", tag: "Thanks for an A+ year. Referrals always welcome!", cost: "About $2", tip: "Pencils, glue sticks or a pocket folder for families."),
        PopByIdea(month: 8, item: "Sunglasses", tag: "The future's so bright!", cost: "About $2", tip: "Bulk party packs work fine."),
        PopByIdea(month: 9, item: "Apples or apple cider mix", tag: "You're the apple of my eye!", cost: "About $2", tip: "Cider packets travel better than fresh apples."),
        PopByIdea(month: 9, item: "Game day snack", tag: "Thanks for being on my team!", cost: "About $2", tip: "Pair it with the local team's schedule."),
        PopByIdea(month: 10, item: "Mini pumpkin", tag: "So glad you're in my patch!", cost: "About $2", tip: "Farm stands sell them cheap by the bin."),
        PopByIdea(month: 10, item: "Candy bag", tag: "No tricks, just treats. Thanks for being a client!", cost: "About $2", tip: "Drop off the week before Halloween."),
        PopByIdea(month: 11, item: "Mini pie or pie crust mix", tag: "Thankful for you. Have a slice of happiness!", cost: "About $4", tip: "Order mini pies from a local bakery and give them a shout out."),
        PopByIdea(month: 11, item: "Hot cocoa packet", tag: "Grateful for clients like you.", cost: "About $1", tip: "Add a candy cane to dress it up."),
        PopByIdea(month: 12, item: "Cookie mix or cookies", tag: "Thanks for a sweet year!", cost: "About $3", tip: "A local bakery tin makes it feel special."),
        PopByIdea(month: 12, item: "Ornament", tag: "Merry everything from your favorite agent!", cost: "About $3", tip: "A first home ornament is perfect for this year's buyers.")
    ]

    static func ideas(for month: Int) -> [PopByIdea] { all.filter { $0.month == month } }

    static func monthKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)"
    }
}
