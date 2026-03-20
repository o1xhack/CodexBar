import SwiftUI
import XCTest
@testable import CodexBarMobile

final class ShareCardRenderTests: XCTestCase {
    @MainActor
    func testRenderAllShareCardPeriods() throws {
        let outputDir = "/tmp/codexbar-share-cards"
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        let configs: [(ShareCardStyleOption, ShareCardTheme, String)] = [
            (.classic, .light, "classic_light"),
            (.classic, .dark, "classic_dark"),
            (.cyber, .dark, "cyber_dark"),
            (.cyber, .light, "cyber_light"),
        ]

        let cases: [(SharePeriod, ShareCardData, String)] = [
            (.today, .previewToday, "today"),
            (.week, .preview7d, "7day"),
            (.month, .preview, "30day"),
        ]

        for (style, theme, styleLabel) in configs {
            for (period, data, label) in cases {
                let view = CostShareCardView(period: period, data: data, theme: theme, style: style)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 3.0

                guard let image = renderer.uiImage, let png = image.pngData() else {
                    XCTFail("Failed to render \(styleLabel)_\(label)")
                    continue
                }

                let path = "\(outputDir)/final_\(styleLabel)_\(label).png"
                try png.write(to: URL(fileURLWithPath: path))
                print("✅ \(styleLabel)_\(label)")
            }
        }
    }
}
