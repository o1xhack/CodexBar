import SwiftUI
import XCTest
@testable import CodexBarMobile

final class ShareCardRenderTests: XCTestCase {
    @MainActor
    func testRenderAllShareCardPeriods() throws {
        let outputDir = "/tmp/codexbar-share-cards"
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        let cases: [(SharePeriod, ShareCardData, String)] = [
            (.today, .previewToday, "today"),
            (.week, .preview7d, "7day"),
            (.month, .preview, "30day"),
        ]

        for (period, data, label) in cases {
            let view = CostShareCardView(period: period, data: data)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3.0

            guard let image = renderer.uiImage, let png = image.pngData() else {
                XCTFail("Failed to render \(label)")
                continue
            }

            let path = "\(outputDir)/final_\(label).png"
            try png.write(to: URL(fileURLWithPath: path))
            print("✅ \(label): \(image.size.width)×\(image.size.height) → \(path)")
        }
    }
}
