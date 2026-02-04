# frozen_string_literal: true

require "committee"

RSpec.configure do |config|
  config.add_setting :committee_options, default: {
    schema_path: ENV.fetch(
      "OPENAPI_SCHEMA_PATH",
      Rails.root.join("../openapi/openapi.yaml").to_s
    ),
    parse_response_by_content_type: false,
    strict: true
  }

  config.define_derived_metadata(file_path: %r{/spec/requests/}) do |metadata|
    metadata[:committee] = true
  end

  config.before(:each, committee: true) do
    schema_path = RSpec.configuration.committee_options[:schema_path]
    @committee_schema = Committee::Drivers::OpenAPI3::Driver.new.parse(File.read(schema_path))
  end
end
