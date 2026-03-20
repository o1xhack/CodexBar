import SwiftUI

struct CostShareSheet: View {
    let insights: CostDashboardInsights
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPeriod: SharePeriod = .month
    @State private var selectedStyle: ShareCardStyleOption = .classic
    @State private var renderedImage: UIImage?
    @State private var showingActivitySheet = false

    private var theme: ShareCardTheme {
        .from(colorScheme)
    }

    private var shareData: ShareCardData {
        ShareCardData(insights: insights, period: selectedPeriod)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Style picker
                Picker(String(localized: "Style"), selection: $selectedStyle) {
                    ForEach(ShareCardStyleOption.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Period picker
                Picker(String(localized: "Period"), selection: $selectedPeriod) {
                    ForEach(SharePeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Card preview
                ScrollView {
                    CostShareCardView(
                        period: selectedPeriod,
                        data: shareData,
                        theme: theme,
                        style: selectedStyle
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.horizontal)
                }

                // Share button
                Button {
                    renderImage()
                    showingActivitySheet = true
                } label: {
                    Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedStyle == .cyber ? CyberTint.accent : .orange)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle(String(localized: "Share Cost Report"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingActivitySheet) {
                if let image = renderedImage {
                    ActivityViewController(activityItems: [image])
                        .presentationDetents([.medium, .large])
                }
            }
        }
        .presentationDetents([.large])
    }

    @MainActor
    private func renderImage() {
        renderedImage = CostShareService.renderImage(
            period: selectedPeriod, data: shareData, theme: theme, style: selectedStyle
        )
    }
}

private enum CyberTint {
    static let accent = Color(red: 0.0, green: 0.90, blue: 0.95)
}

// MARK: - UIActivityViewController wrapper for SwiftUI

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CostShareSheet(
        insights: CostDashboardInsights(snapshot: PreviewData.sampleSnapshot)
    )
}
