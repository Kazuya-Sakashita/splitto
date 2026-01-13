RSpec.configure do |config|
  config.after(:each, type: :request) do |example|
    next unless example.exception
    next unless defined?(response) && response

    warn "\n--- DEBUG (request spec failed) ---"
    warn "Status: #{response.status}"
    warn "Headers: #{response.headers.to_h.slice('Content-Type', 'Location').inspect}"
    warn "Body: #{response.body}"
    warn "-----------------------------------\n"
  end
end
