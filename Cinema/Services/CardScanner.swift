import Foundation
import UIKit
import Vision

/// Reads business cards and paper sign in sheets with on device text recognition.
enum CardScanner {
    struct Contact: Identifiable, Hashable {
        var id = UUID()
        var name: String
        var phone: String
        var email: String
        var company: String
        var include = true
    }

    enum Mode: String, CaseIterable, Identifiable {
        case card, sheet
        var id: String { rawValue }
        var title: String { self == .card ? "Business card" : "Sign in sheet" }
    }

    struct Line {
        let text: String
        let box: CGRect // normalized, origin bottom left
    }

    static func recognize(_ image: UIImage) async throws -> [Line] {
        guard let cgImage = image.cgImage else { return [] }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
            return (request.results ?? []).compactMap { observation -> Line? in
                guard let best = observation.topCandidates(1).first else { return nil }
                return Line(text: best.string, box: observation.boundingBox)
            }
        }.value
    }

    // MARK: Parsing

    private static let companyWords = ["realty", "realtors", "real estate", "properties", "group", "llc", "inc", "mortgage", "title", "insurance", "company", "homes", "brokerage", "team", "keller williams", "coldwell", "re/max", "remax", "compass", "century 21", "exp", "sotheby", "berkshire", "bank", "lending"]

    static func phone(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue) else { return nil }
        return detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))?.phoneNumber
    }

    static func email(in text: String) -> String? {
        let pattern = #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#
        guard let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else { return nil }
        return String(text[range]).lowercased()
    }

    private static func looksLikeName(_ text: String) -> Bool {
        let words = text.split(separator: " ")
        guard (2...4).contains(words.count), text.count <= 40 else { return false }
        guard text.rangeOfCharacter(from: .decimalDigits) == nil, !text.contains("@"), !text.contains(".com") else { return false }
        let lower = text.lowercased()
        if companyWords.contains(where: { lower.contains($0) }) { return false }
        let titles = ["agent", "broker", "realtor", "associate", "manager", "owner", "president", "director", "officer", "specialist", "consultant", "licensed"]
        if titles.contains(where: { lower.contains($0) }) { return false }
        return words.allSatisfy { $0.first?.isUppercase == true || $0.count <= 2 }
    }

    /// One contact from a business card: the name, phone, email and company lines.
    static func parseCard(_ lines: [Line]) -> [Contact] {
        let ordered = lines.sorted { $0.box.midY > $1.box.midY }.map(\.text)
        let all = ordered.joined(separator: "\n")
        let phoneValue = ordered.compactMap { phone(in: $0) }.first ?? ""
        let emailValue = email(in: all) ?? ""
        // The biggest text on a card is usually the name.
        let byHeight = lines.sorted { $0.box.height > $1.box.height }.map(\.text)
        let name = byHeight.first(where: looksLikeName) ?? ordered.first(where: looksLikeName) ?? ""
        let company = ordered.first { line in
            let lower = line.lowercased()
            return companyWords.contains { lower.contains($0) }
        } ?? ""
        guard !name.isEmpty || !phoneValue.isEmpty || !emailValue.isEmpty else { return [] }
        return [Contact(name: name, phone: phoneValue, email: emailValue, company: company)]
    }

    /// One contact per handwritten or printed row of a sign in sheet.
    static func parseSheet(_ lines: [Line]) -> [Contact] {
        let sorted = lines.sorted { $0.box.midY > $1.box.midY }
        var rows: [[Line]] = []
        for line in sorted {
            if let last = rows.last?.first, abs(last.box.midY - line.box.midY) < max(0.012, line.box.height * 0.6) {
                rows[rows.count - 1].append(line)
            } else {
                rows.append([line])
            }
        }
        let headerWords = ["name", "phone", "email", "agent?", "pre-approved", "welcome", "please sign in", "hosted by", "scan", "your information"]
        return rows.compactMap { row -> Contact? in
            let cells = row.sorted { $0.box.minX < $1.box.minX }.map(\.text)
            let joined = cells.joined(separator: " ")
            let lower = joined.lowercased()
            if headerWords.filter({ lower.contains($0) }).count >= 2 { return nil }
            let phoneValue = phone(in: joined) ?? ""
            let emailValue = email(in: joined) ?? ""
            guard !phoneValue.isEmpty || !emailValue.isEmpty else { return nil }
            let nameCell = cells.first { cell in
                cell.rangeOfCharacter(from: .decimalDigits) == nil && !cell.contains("@") && cell.count >= 3
                    && !["yes", "no", "y", "n"].contains(cell.lowercased())
            } ?? ""
            return Contact(name: nameCell.capitalized, phone: phoneValue, email: emailValue, company: "")
        }
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
