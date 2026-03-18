import Foundation

enum MobileChartAxisFormatter {
    static func axisValues(for values: [Double], targetTickCount: Int = 4) -> [Double] {
        let maxValue = max(values.max() ?? 0, 0)
        let step = self.axisStep(for: maxValue, targetTickCount: targetTickCount)
        let upperBound = max(step, ceil(maxValue / step) * step)
        let tickCount = Int((upperBound / step).rounded())
        return (0...tickCount).map { Double($0) * step }
    }

    static func axisLabel(for value: Double) -> String {
        Int(value.rounded()).formatted()
    }

    private static func axisStep(for maxValue: Double, targetTickCount: Int) -> Double {
        guard maxValue > 0 else { return 1 }

        let clampedTickCount = max(targetTickCount, 1)
        let rawStep = maxValue / Double(clampedTickCount)
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalizedStep = rawStep / magnitude
        let niceStep: Double

        switch normalizedStep {
        case ..<1.5:
            niceStep = 1
        case ..<3:
            niceStep = 2
        case ..<7:
            niceStep = 5
        default:
            niceStep = 10
        }

        return max(1, niceStep * magnitude)
    }
}
