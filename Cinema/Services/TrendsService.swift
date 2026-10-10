import Foundation

/// Where the Trends feed comes from.
///
/// With the backend on, the `trends` Edge Function returns the formats our team
/// curates plus real example videos it pulls each day (Instagram hashtag top media
/// through the official Graph API, and links our team adds for TikTok and Facebook).
/// Without it, the built in `TrendLibrary` keeps the feed working.
struct TrendsService {
    var client: SupabaseClient? = SupabaseClient.shared

    var isLive: Bool { client != nil }

    private struct FeedRequest: Encodable { var country = "US" }
    /// Heat and example videos for a format, new or built in.
    struct TrendUpdate: Decodable {
        var id: String
        var heat: TrendHeat?
        var examples: [Lossy<TrendExample>]?
    }

    private struct FeedResponse: Decodable {
        /// Whole new formats our team wrote.
        var trends: [Lossy<Trend>]
        var updates: [Lossy<TrendUpdate>]?
        var updatedAt: Date?
    }

    /// Fresh formats and examples merged over the built in list.
    func fetch() async throws -> (trends: [Trend], updatedAt: Date?) {
        guard let client else { return (TrendLibrary.all, nil) }
        let response = try await client.invoke("trends", body: FeedRequest(), as: FeedResponse.self)
        var merged = TrendLibrary.merge(response.trends.compactMap(\.value))
        for update in (response.updates ?? []).compactMap(\.value) {
            guard let index = merged.firstIndex(where: { $0.id == update.id }) else { continue }
            if let heat = update.heat { merged[index].heat = heat }
            if let examples = update.examples { merged[index].examples = examples.compactMap(\.value) }
        }
        return (merged, response.updatedAt)
    }

    private struct RemixRequest: Encodable {
        struct ListingInfo: Encodable {
            var address: String
            var city: String
            var price: Int
            var beds: Int
            var baths: Double
            var squareFeet: Int?
            var features: [String]
            var description: String
        }
        struct Pasted: Encodable {
            var platform: String?
            var url: String
            var caption: String?
            var creator: String?
        }
        var trendId: String
        var trendTitle: String
        var format: String
        var beats: [String]
        var exampleScript: String
        var seconds: Int
        var cityId: String
        var listing: ListingInfo?
        var pasted: Pasted?
    }

    private struct RemixResponse: Decodable {
        var title: String
        var hook: String
        var shots: [String]
        var script: String
        var targetSeconds: Int?
        var whyItWorks: String?
    }

    /// Claude writes the agent's version when the backend is on. Otherwise the template is filled in locally.
    func makeIdea(from trend: Trend, context: TrendContext, pasted: PastedVideo?) async -> Idea {
        let inspiredBy = pasted.map { $0.creditLine }
        let local = trend.idea(context, inspiredBy: inspiredBy)
        guard let client else { return local }
        let listing = context.listing.map {
            RemixRequest.ListingInfo(address: $0.address, city: $0.cityLine, price: $0.price, beds: $0.beds, baths: $0.baths, squareFeet: $0.squareFeet, features: $0.features.map(\.title), description: $0.description)
        }
        let body = RemixRequest(
            trendId: trend.id,
            trendTitle: trend.title,
            format: trend.format,
            beats: trend.beats,
            exampleScript: trend.script,
            seconds: trend.seconds,
            cityId: context.city.id,
            listing: listing,
            pasted: pasted.map { .init(platform: $0.platform?.rawValue, url: $0.url.absoluteString, caption: $0.caption, creator: $0.creator) }
        )
        do {
            let result = try await client.invoke("remix-trend", body: body, as: RemixResponse.self)
            guard !result.script.isEmpty, !result.shots.isEmpty else { return local }
            return Idea(
                title: result.title,
                hook: result.hook,
                category: trend.category,
                shots: result.shots,
                script: result.script,
                targetSeconds: result.targetSeconds ?? trend.seconds,
                whyItWorks: result.whyItWorks ?? trend.whyItWorks,
                remixedFrom: inspiredBy ?? trend.title,
                cityName: context.cityName
            )
        } catch {
            return local
        }
    }
}

/// Decodes what it can and skips the rest, so one bad row never empties the feed.
struct Lossy<Value: Decodable>: Decodable {
    var value: Value?
    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

// MARK: - Pasted links

/// A video the agent saw and wants to copy the idea of.
struct PastedVideo: Hashable {
    var url: URL
    var platform: TrendPlatform?
    var caption: String?
    var creator: String?
    var thumbnailURL: URL?

    var creditLine: String {
        if let creator, !creator.isEmpty { return "\(creator) on \(platform?.title ?? "social")" }
        return "a \(platform?.title ?? "social") video"
    }
}

enum VideoLinkInspector {
    /// Pulls the first link out of whatever was pasted (share sheets often add text around it).
    static func firstURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let url = match.url, url.scheme?.hasPrefix("http") == true {
            return url
        }
        return nil
    }

    private struct OEmbed: Decodable {
        var title: String?
        var authorName: String?
        var authorUniqueId: String?
        var thumbnailUrl: String?
    }

    /// TikTok's public oEmbed gives the caption, creator and cover image.
    /// Instagram and Facebook need an app token for theirs, so for those we only know the platform.
    static func inspect(_ url: URL) async -> PastedVideo {
        var video = PastedVideo(url: url, platform: TrendPlatform.detect(url))
        guard video.platform == .tiktok else { return video }
        let target = await resolveShortLink(url)
        video.url = target
        var components = URLComponents(string: "https://www.tiktok.com/oembed")
        components?.queryItems = [URLQueryItem(name: "url", value: target.absoluteString)]
        guard let endpoint = components?.url else { return video }
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 10
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return video }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let embed = try? decoder.decode(OEmbed.self, from: data) else { return video }
        video.caption = embed.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let handle = embed.authorUniqueId, !handle.isEmpty {
            video.creator = "@\(handle)"
        } else {
            video.creator = embed.authorName
        }
        video.thumbnailURL = embed.thumbnailUrl.flatMap(URL.init(string:))
        return video
    }

    /// vm.tiktok.com and vt.tiktok.com links redirect to the full video URL.
    private static func resolveShortLink(_ url: URL) async -> URL {
        guard let host = url.host?.lowercased(), host.hasPrefix("vm.") || host.hasPrefix("vt.") else { return url }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 8
        guard let (_, response) = try? await URLSession.shared.data(for: request), let final = response.url else { return url }
        return final
    }

    /// The built in format that best matches a caption, if any word lines up.
    static func bestMatch(for caption: String?, in trends: [Trend]) -> Trend? {
        guard let caption, !caption.isEmpty else { return nil }
        let scored = trends.map { ($0, $0.matchScore(caption)) }.filter { $0.1 > 0 }
        return scored.max { $0.1 < $1.1 }?.0
    }
}
