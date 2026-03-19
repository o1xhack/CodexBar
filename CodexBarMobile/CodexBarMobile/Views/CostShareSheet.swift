import SwiftUI

struct CostShareSheet: View {
    let insights: CostDashboardInsights
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: SharePeriod = .month
    @State private var renderedImage: UIImage?

    private var shareData: ShareCardData {
        ShareCardData(insights: insights, period: selectedPeriod)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
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
                    CostShareCardView(period: selectedPeriod, data: shareData)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        .padding(.horizontal)
                }

                // Share button
                ShareLink(
                    item: renderedImage ?? UIImage(),
                    preview: SharePreview(
                        String(localized: "AI Coding Spend"),
                        image: Image(uiImage: renderedImage ?? UIImage())
                    )
                ) {
                    Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
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
            .onChange(of: selectedPeriod) {
                renderImage()
            }
            .onAppear {
                renderImage()
            }
        }
        .presentationDetents([.large])
    }

    @MainActor
    private func renderImage() {
        renderedImage = CostShareService.renderImage(period: selectedPeriod, data: shareData)
    }
}

// MARK: - ShareLink Transferable conformance for UIImage

extension UIImage: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            guard let data = image.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
    }
}

#Preview {
    CostShareSheet(
        insights: CostDashboardInsights(snapshot: PreviewData.sampleSnapshot)
    )
}
