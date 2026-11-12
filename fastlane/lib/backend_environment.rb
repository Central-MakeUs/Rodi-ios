require "uri"

module BackendEnvironment
  EXPECTED = {
    dev: { bundle_id: "com.dororong.rodi.dev", host: "dev-api.stillstar.store" },
    prod: { bundle_id: "com.dororong.rodi", host: "api.stillstar.store" }
  }.freeze

  def self.validate!(environment, settings)
    expected = EXPECTED.fetch(environment)
    unless settings["PRODUCT_BUNDLE_IDENTIFIER"] == expected[:bundle_id] &&
           settings["RODI_ENVIRONMENT"] == environment.to_s
      raise ArgumentError, "Bundle ID and RODI_ENVIRONMENT do not match #{environment}."
    end

    begin
      uri = URI.parse(settings.fetch("RODI_API_BASE_URL", ""))
      valid = uri.is_a?(URI::HTTPS) && uri.host == expected[:host] && uri.port == 443 &&
              uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil? &&
              ["", "/"].include?(uri.path)
      # 기본 포트도 명시한 주소는 앱의 동일한 검증 기준에 맞춰 거부합니다.
      valid &&= ["https://#{expected[:host]}", "https://#{expected[:host]}/"].include?(settings["RODI_API_BASE_URL"])
    rescue URI::InvalidURIError
      valid = false
    end
    raise ArgumentError, "RODI_API_BASE_URL does not match the #{environment} HTTPS server." unless valid
    true
  end

  def self.validate_upload!(environment, settings)
    validate!(environment, settings)
    if environment == :dev && settings["RODI_BACKEND_COMPATIBILITY_VERIFIED"] != "YES"
      raise ArgumentError, "Dev backend compatibility is unverified. Resolve API-004 and QA-048 before TestFlight upload."
    end
    true
  end
end
