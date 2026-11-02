import Foundation

/// 환경·앱 식별자·서버가 일치하는 설정만 앱 조립에 사용합니다.
struct AppBackendConfiguration {
    let environment: AppEnvironment
    let bundleIdentifier: String
    let baseURL: URL

    enum ValidationError: Error {
        case invalidEnvironment
        case mismatchedIdentity
        case invalidServer
    }

    init(environment: String, bundleIdentifier: String, baseURL: String) throws {
        guard let environment = AppEnvironment(rawValue: environment) else {
            throw ValidationError.invalidEnvironment
        }
        let expectedBundleID = environment.isProduction ? "com.dororong.rodi" : "com.dororong.rodi.dev"
        let expectedHost = environment.isProduction ? "api.stillstar.store" : "dev-api.stillstar.store"
        guard bundleIdentifier == expectedBundleID else {
            throw ValidationError.mismatchedIdentity
        }
        guard let url = URL(string: baseURL),
              url.scheme == "https", url.host == expectedHost,
              url.port == nil, url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else {
            throw ValidationError.invalidServer
        }
        self.environment = environment
        self.bundleIdentifier = bundleIdentifier
        self.baseURL = url
    }

    static var current: Self {
        do {
            return try Self(
                environment: Bundle.main.rodiConfigurationString(for: "RODI_ENVIRONMENT"),
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
                baseURL: Bundle.main.rodiConfigurationString(for: "RODI_API_BASE_URL")
            )
        } catch {
            // 잘못된 환경에서 인증 요청을 시작하거나 다른 서버로 우회하지 않습니다.
            preconditionFailure("RODI backend environment configuration is invalid.")
        }
    }

    var tokenService: String {
        environment.isProduction ? bundleIdentifier : "\(bundleIdentifier).\(baseURL.host!)"
    }
}
