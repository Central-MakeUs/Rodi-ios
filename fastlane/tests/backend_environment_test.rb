require "minitest/autorun"
require_relative "../lib/backend_environment"

class BackendEnvironmentTest < Minitest::Test
  def settings(environment)
    expected = BackendEnvironment::EXPECTED.fetch(environment)
    {
      "PRODUCT_BUNDLE_IDENTIFIER" => expected[:bundle_id],
      "RODI_ENVIRONMENT" => environment.to_s,
      "RODI_API_BASE_URL" => "https://#{expected[:host]}"
    }
  end

  def test_matching_environments
    %i[dev prod].each { |environment| assert BackendEnvironment.validate!(environment, settings(environment)) }
  end

  def test_mixed_identity_and_environment_are_rejected
    ["PRODUCT_BUNDLE_IDENTIFIER", "RODI_ENVIRONMENT", "RODI_API_BASE_URL"].each do |key|
      mixed = settings(:dev).merge(key => settings(:prod)[key])
      assert_raises(ArgumentError) { BackendEnvironment.validate!(:dev, mixed) }
    end
  end

  def test_invalid_urls_are_rejected
    ["", "http://dev-api.stillstar.store", "https://dev-api.stillstar.store.evil.example",
     "https://dev-api.stillstar.store:443", "https://dev-api.stillstar.store/path",
     "https://dev-api.stillstar.store?token=example", "https://user@dev-api.stillstar.store"].each do |url|
      assert_raises(ArgumentError) do
        BackendEnvironment.validate!(:dev, settings(:dev).merge("RODI_API_BASE_URL" => url))
      end
    end
  end

  def test_dev_upload_stays_blocked_until_compatibility_is_verified
    assert_raises(ArgumentError) { BackendEnvironment.validate_upload!(:dev, settings(:dev)) }
    assert BackendEnvironment.validate_upload!(:dev, settings(:dev).merge("RODI_BACKEND_COMPATIBILITY_VERIFIED" => "YES"))
    assert BackendEnvironment.validate_upload!(:prod, settings(:prod))
  end
end
