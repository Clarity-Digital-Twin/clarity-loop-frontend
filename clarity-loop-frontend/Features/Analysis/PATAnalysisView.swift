import Charts
import SwiftData
import SwiftUI

// MARK: - Feature Definition

private struct FeatureDefinition {
    let key: String
    let title: String
    let unit: String
    let icon: String
}

struct PATAnalysisView: View {
    @State private var viewModel: PATAnalysisViewModel
    let analysisId: String?

    init(analysisId: String? = nil, viewModel: PATAnalysisViewModel) {
        self.analysisId = analysisId
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.analysisState {
                case .idle:
                    IdleAnalysisView()
                case .loading:
                    LoadingAnalysisView()
                case let .loaded(result):
                    CompletedAnalysisView(result: result)
                case .error:
                    ErrorAnalysisView(message: viewModel.analysisState.errorMessage ?? "Analysis failed", onRetry: {
                        Task {
                            await viewModel.retryAnalysis()
                        }
                    })
                case .empty:
                    EmptyAnalysisView()
                }
            }
            .navigationTitle("PAT Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if let analysisId {
                await viewModel.startCustomAnalysis(for: analysisId)
            } else {
                await viewModel.startStepAnalysis()
            }
        }
    }
}

// MARK: - Subviews

private struct IdleAnalysisView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Ready to Analyze")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "We'll analyze your movement patterns using advanced AI to provide insights into your sleep and activity."
            )
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .padding()
    }
}

private struct LoadingAnalysisView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))

            VStack(spacing: 8) {
                Text("Analyzing Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Our AI is processing your movement patterns. This may take a few minutes.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Progress steps indicator
            VStack(alignment: .leading, spacing: 12) {
                ProgressStepView(title: "Processing movement data", isActive: true)
                ProgressStepView(title: "Extracting activity patterns", isActive: false)
                ProgressStepView(title: "Generating insights", isActive: false)
            }
            .padding(.top)
        }
        .padding()
    }
}

private struct ProgressStepView: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack {
            Image(systemName: isActive ? "circle.fill" : "circle")
                .foregroundColor(isActive ? .blue : .secondary)
            Text(title)
                .foregroundColor(isActive ? .primary : .secondary)
            Spacer()
        }
    }
}

private struct CompletedAnalysisView: View {
    let result: PATAnalysisResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Analysis Complete")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    if let completedAt = result.completedAt {
                        Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Confidence Score
                if let confidence = result.confidence {
                    ConfidenceScoreView(confidence: confidence)
                        .padding(.horizontal)
                }

                // PAT Features
                if let features = result.patFeatures {
                    PATFeaturesView(features: features)
                        .padding(.horizontal)
                }

                // Sleep Stage Visualization (if available)
                if let sleepStages = extractSleepStages(from: result.patFeatures) {
                    SleepStageHypnogramView(sleepStages: sleepStages)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func extractSleepStages(from features: [String: AnyCodable]?) -> [SleepStageData]? {
        guard
            let features,
            let sleepStagesValue = features["sleep_stages"],
            let sleepStagesArray = sleepStagesValue.value as? [[String: Any]] else {
            return nil
        }

        return sleepStagesArray.compactMap { stageDict in
            guard
                let timestamp = stageDict["timestamp"] as? TimeInterval,
                let stage = stageDict["stage"] as? String else {
                return nil
            }

            return SleepStageData(
                timestamp: Date(timeIntervalSince1970: timestamp),
                stage: SleepStage(rawValue: stage) ?? .awake,
                duration: stageDict["duration"] as? TimeInterval ?? 30.0
            )
        }
    }
}

private struct ConfidenceScoreView: View {
    let confidence: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Confidence")
                .font(.headline)

            HStack {
                Gauge(value: confidence, in: 0...1) {
                    Text("Confidence")
                } currentValueLabel: {
                    Text("\(Int(confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(confidenceColor(for: confidence))
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Quality: \(confidenceDescription(for: confidence))")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Based on data quality and pattern recognition accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0: .green
        case 0.6..<0.8: .orange
        default: .red
        }
    }

    private func confidenceDescription(for confidence: Double) -> String {
        switch confidence {
        case 0.8...1.0: "High"
        case 0.6..<0.8: "Medium"
        default: "Low"
        }
    }
}

private struct PATFeaturesView: View {
    let features: [String: AnyCodable]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Metrics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16) {
                ForEach(Array(relevantFeatures.enumerated()), id: \.offset) { _, feature in
                    if let value = features[feature.key] {
                        MetricCardView(
                            title: feature.title,
                            value: formatFeatureValue(value, unit: feature.unit),
                            unit: feature.unit,
                            icon: feature.icon
                        )
                    }
                }
            }
        }
    }

    private var relevantFeatures: [FeatureDefinition] {
        [
            FeatureDefinition(key: "sleep_efficiency", title: "Sleep Efficiency", unit: "%", icon: "bed.double.fill"),
            FeatureDefinition(key: "total_sleep_time", title: "Total Sleep", unit: "hrs", icon: "moon.fill"),
            FeatureDefinition(key: "wake_after_sleep_onset", title: "WASO", unit: "min", icon: "eye.fill"),
            FeatureDefinition(key: "sleep_latency", title: "Sleep Latency", unit: "min", icon: "timer"),
            FeatureDefinition(key: "rem_percentage", title: "REM Sleep", unit: "%", icon: "brain.head.profile"),
            FeatureDefinition(key: "deep_sleep_percentage", title: "Deep Sleep", unit: "%", icon: "zzz"),
        ]
    }

    private func formatFeatureValue(_ value: AnyCodable, unit: String) -> String {
        if let doubleValue = value.value as? Double {
            switch unit {
            case "%":
                return String(format: "%.1f", doubleValue * 100)
            case "hrs":
                return String(format: "%.1f", doubleValue / 60.0) // Convert minutes to hours
            case "min":
                return String(format: "%.0f", doubleValue)
            default:
                return String(format: "%.1f", doubleValue)
            }
        }
        return "N/A"
    }
}

private struct MetricCardView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.semibold)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

private struct SleepStageHypnogramView: View {
    let sleepStages: [SleepStageData]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Stages")
                .font(.headline)

            Chart(sleepStages) { stage in
                RectangleMark(
                    x: .value("Time", stage.timestamp),
                    y: .value("Stage", stage.stage.numericValue),
                    width: .fixed(stage.duration * 100), // Convert to appropriate pixel width
                    height: 0.8
                )
                .foregroundStyle(stage.stage.color)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...4)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4]) { value in
                    AxisValueLabel {
                        Text(SleepStage.allCases[value.as(Int.self) ?? 0].displayName)
                            .font(.caption)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                ForEach(SleepStage.allCases, id: \.self) { stage in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stage.color)
                            .frame(width: 8, height: 8)
                        Text(stage.displayName)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct ErrorAnalysisView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Analysis Failed")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Retry Analysis", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Data Available")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "There isn't enough movement data to perform a PAT analysis. Try again after collecting more health data."
            )
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Supporting Types

struct SleepStageData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let stage: SleepStage
    let duration: TimeInterval
}

enum SleepStage: String, CaseIterable {
    case awake
    case light
    case deep
    case rem

    var displayName: String {
        switch self {
        case .awake: "Awake"
        case .light: "Light"
        case .deep: "Deep"
        case .rem: "REM"
        }
    }

    var color: Color {
        switch self {
        case .awake: .red
        case .light: .blue
        case .deep: .purple
        case .rem: .green
        }
    }

    var numericValue: Int {
        switch self {
        case .awake: 4
        case .rem: 3
        case .light: 2
        case .deep: 1
        }
    }
}

// MARK: - Preview

#Preview {
    if
        let previewAPIClient = APIClient(
            baseURLString: AppConfig.previewAPIBaseURL,
            tokenProvider: { nil }
        ) {
        let previewAuthService = AuthService(apiClient: previewAPIClient)

        let container = try! ModelContainer(for: PATAnalysis.self, HealthMetric.self)
        let modelContext = container.mainContext
        PATAnalysisView(
            analysisId: nil,
            viewModel: PATAnalysisViewModel(
                modelContext: modelContext,
                analyzePATDataUseCase: AnalyzePATDataUseCase(
                    apiClient: previewAPIClient,
                    healthKitService: HealthKitService(apiClient: previewAPIClient),
                    authService: previewAuthService
                ),
                apiClient: previewAPIClient,
                patRepository: PATAnalysisRepository(modelContext: modelContext),
                healthRepository: HealthRepository(modelContext: modelContext)
            )
        )
    } else {
        Text("Failed to create preview client")
    }
}
