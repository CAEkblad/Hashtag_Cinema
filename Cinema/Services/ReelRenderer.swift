import AVFoundation
import UIKit

/// Turns listing photos into a vertical 1080x1920 MP4 with a slow zoom on each
/// photo, a branded caption bar and an end card. Runs on the phone, no upload.
enum ReelRenderer {
    struct Options {
        var tag: String
        var title: String
        var subtitle: String
        var agentName: String
        var agentLine: String
        var accent: UIColor
        var secondsPerPhoto: Double = 2.5
    }

    enum RenderError: Error { case setup, writing }

    static let size = CGSize(width: 1080, height: 1920)
    static let fps: Int32 = 30

    static func render(photos: [UIImage], options: Options, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cinema-reel-\(UUID().uuidString.prefix(6)).mp4")
        try? FileManager.default.removeItem(at: url)

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 8_000_000]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height)
        ])
        guard writer.canAdd(input) else { throw RenderError.setup }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? RenderError.setup }
        writer.startSession(atSourceTime: .zero)

        let overlay = captionOverlay(options)
        let endCard = endCardImage(options)
        let framesPerPhoto = max(1, Int(options.secondsPerPhoto * Double(fps)))
        let endFrames = Int(fps) * 2
        let totalFrames = photos.count * framesPerPhoto + endFrames
        var frame: Int64 = 0

        func append(_ draw: (CGContext) -> Void) async throws {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)
            }
            guard let pool = adaptor.pixelBufferPool else { throw RenderError.writing }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let buffer else { throw RenderError.writing }
            CVPixelBufferLockBaseAddress(buffer, [])
            if let context = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer),
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) {
                context.setFillColor(UIColor.black.cgColor)
                context.fill(CGRect(origin: .zero, size: size))
                draw(context)
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: frame, timescale: fps)) else {
                throw writer.error ?? RenderError.writing
            }
            frame += 1
            if frame % 15 == 0 { progress(Double(frame) / Double(totalFrames)) }
        }

        for (index, photo) in photos.enumerated() {
            guard let filled = aspectFill(photo) else { continue }
            let zoomIn = index % 2 == 0
            for step in 0..<framesPerPhoto {
                let t = Double(step) / Double(framesPerPhoto)
                let scale = zoomIn ? 1.0 + 0.10 * t : 1.10 - 0.10 * t
                try await append { context in
                    let w = size.width * scale
                    let h = size.height * scale
                    context.draw(filled, in: CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h))
                    if let overlay { context.draw(overlay, in: CGRect(origin: .zero, size: size)) }
                }
            }
        }
        for _ in 0..<endFrames {
            try await append { context in
                if let endCard { context.draw(endCard, in: CGRect(origin: .zero, size: size)) }
            }
        }

        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? RenderError.writing }
        progress(1)
        return url
    }

    /// The photo cropped to fill the 9:16 frame, upright.
    private static func aspectFill(_ image: UIImage) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let w = image.size.width * scale
            let h = image.size.height * scale
            image.draw(in: CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h))
        }
        return rendered.cgImage
    }

    private static func captionOverlay(_ options: Options) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            let colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.75).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height * 0.55), end: CGPoint(x: 0, y: size.height), options: [])
            }

            let tagFont = UIFont.systemFont(ofSize: 44, weight: .heavy)
            let tag = options.tag.uppercased() as NSString
            let tagSize = tag.size(withAttributes: [.font: tagFont, .kern: 4])
            let tagRect = CGRect(x: 72, y: 150, width: tagSize.width + 56, height: tagSize.height + 28)
            options.accent.setFill()
            UIBezierPath(roundedRect: tagRect, cornerRadius: tagRect.height / 2).fill()
            tag.draw(at: CGPoint(x: tagRect.minX + 28, y: tagRect.minY + 14), withAttributes: [.font: tagFont, .kern: 4, .foregroundColor: UIColor.white])

            let titleStyle = NSMutableParagraphStyle()
            titleStyle.lineBreakMode = .byWordWrapping
            let title = options.title as NSString
            title.draw(in: CGRect(x: 72, y: size.height - 520, width: size.width - 144, height: 220), withAttributes: [
                .font: UIFont.systemFont(ofSize: 76, weight: .black),
                .foregroundColor: UIColor.white,
                .paragraphStyle: titleStyle
            ])
            (options.subtitle as NSString).draw(in: CGRect(x: 72, y: size.height - 290, width: size.width - 144, height: 80), withAttributes: [
                .font: UIFont.systemFont(ofSize: 46, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.92)
            ])
            (options.agentName as NSString).draw(in: CGRect(x: 72, y: size.height - 190, width: size.width - 144, height: 60), withAttributes: [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: options.accent.withAlphaComponent(1)
            ])
        }
        return image.cgImage
    }

    private static func endCardImage(_ options: Options) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            options.accent.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let center = NSMutableParagraphStyle()
            center.alignment = .center
            ("Want a private tour?" as NSString).draw(in: CGRect(x: 80, y: 700, width: size.width - 160, height: 120), withAttributes: [
                .font: UIFont.systemFont(ofSize: 72, weight: .black),
                .foregroundColor: UIColor.white,
                .paragraphStyle: center
            ])
            (options.agentName as NSString).draw(in: CGRect(x: 80, y: 880, width: size.width - 160, height: 80), withAttributes: [
                .font: UIFont.systemFont(ofSize: 56, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: center
            ])
            (options.agentLine as NSString).draw(in: CGRect(x: 80, y: 980, width: size.width - 160, height: 160), withAttributes: [
                .font: UIFont.systemFont(ofSize: 40, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: center
            ])
            ("Made with #Cinema" as NSString).draw(in: CGRect(x: 80, y: size.height - 180, width: size.width - 160, height: 60), withAttributes: [
                .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.75),
                .paragraphStyle: center
            ])
        }
        return image.cgImage
    }
}
