@testable import clarity_loop_frontend
import Foundation

// Correct mock that matches the real APIClientProtocol
class MockAPIClient: APIClientProtocol {
    // MARK: - Control Properties

    var shouldSucceed = true
    var mockError: Error = APIError.unauthorized

    // Mock responses
    var mockInsightHistory = InsightHistoryResponseDTO(
        success: true,
        data: InsightHistoryDataDTO(
            insights: [],
            totalCount: 0,
            hasMore: false,
            pagination: PaginationMetaDTO(
                page: 1,
                limit: 10
            )
        ),
        metadata: nil
    )

    // MARK: - Authentication

    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        guard shouldSucceed else { throw mockError }
        return RegistrationResponseDTO(
            userId: UUID(),
            email: requestDTO.email,
            status: "registered",
            verificationEmailSent: true,
            createdAt: Date()
        )
    }

    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        guard shouldSucceed else { throw mockError }
        return LoginResponseDTO(
            user: UserSessionResponseDTO(
                id: UUID().uuidString,
                email: requestDTO.email,
                displayName: "Test User",
                avatarUrl: nil,
                provider: "email",
                role: "patient",
                isActive: true,
                isEmailVerified: true,
                preferences: UserPreferencesResponseDTO(
                    theme: "light",
                    notifications: true,
                    language: "en"
                ),
                metadata: UserMetadataResponseDTO(
                    lastLogin: Date(),
                    loginCount: 1,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ),
            tokens: TokenResponseDTO(
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600
            )
        )
    }

    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        guard shouldSucceed else { throw mockError }
        return TokenResponseDTO(
            accessToken: "mock_refreshed_token",
            refreshToken: requestDTO.refreshToken,
            tokenType: "bearer",
            expiresIn: 3600
        )
    }

    func logout() async throws -> MessageResponseDTO {
        guard shouldSucceed else { throw mockError }
        return MessageResponseDTO(message: "Successfully logged out")
    }

    func getCurrentUser() async throws -> UserSessionResponseDTO {
        guard shouldSucceed else { throw mockError }
        return UserSessionResponseDTO(
            id: UUID().uuidString,
            email: "test@example.com",
            displayName: "Test User",
            avatarUrl: nil,
            provider: "email",
            role: "patient",
            isActive: true,
            isEmailVerified: true,
            preferences: UserPreferencesResponseDTO(
                theme: "light",
                notifications: true,
                language: "en"
            ),
            metadata: UserMetadataResponseDTO(
                lastLogin: Date(),
                loginCount: 1,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }

    func verifyEmail(email: String, code: String) async throws -> LoginResponseDTO {
        guard shouldSucceed else { throw mockError }
        return LoginResponseDTO(
            user: UserSessionResponseDTO(
                id: UUID().uuidString,
                email: email,
                displayName: "Test User",
                avatarUrl: nil,
                provider: "email",
                role: "patient",
                isActive: true,
                isEmailVerified: true,
                preferences: UserPreferencesResponseDTO(
                    theme: "light",
                    notifications: true,
                    language: "en"
                ),
                metadata: UserMetadataResponseDTO(
                    lastLogin: Date(),
                    loginCount: 1,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ),
            tokens: TokenResponseDTO(
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600
            )
        )
    }

    func resendVerificationEmail(email: String) async throws -> MessageResponseDTO {
        guard shouldSucceed else { throw mockError }
        return MessageResponseDTO(message: "Verification email sent")
    }

    // MARK: - Health Data

    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getProcessingStatus(id: UUID) async throws -> HealthDataProcessingStatusDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    // MARK: - Insights

    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        guard shouldSucceed else { throw mockError }
        return mockInsightHistory
    }

    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getInsight(id: String) async throws -> InsightGenerationResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    // MARK: - PAT Analysis

    func analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> StepAnalysisResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> ActigraphyAnalysisResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func getPATServiceHealth() async throws -> ServiceStatusResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}
