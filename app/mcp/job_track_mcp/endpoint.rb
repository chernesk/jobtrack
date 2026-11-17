module JobTrackMcp
  # A Rack app, mounted at /mcp, that speaks MCP over HTTP ("streamable HTTP"). It wraps the SDK's
  # transport with the same bearer-token check the JSON API uses.
  #
  # - Stateless: every request is self-contained and nothing is kept between them, which suits a
  #   single-process app and means a restart never strands a client.
  # - Plain JSON responses (no event stream), which every client handles.
  # - The SDK's Host/Origin ("DNS rebinding") check is off. It exists to protect unauthenticated
  #   servers on localhost from web pages, and here every request must carry a token a web page
  #   cannot know. Leaving it on would reject any address but localhost, such as a NAS hostname.
  class Endpoint
    def initialize(server = Server.build)
      @transport = MCP::Server::Transports::StreamableHTTPTransport.new(
        server, stateless: true, enable_json_response: true, dns_rebinding_protection: false
      )
    end

    def call(env)
      token = ApiToken.authenticate(bearer_token(env))
      return unauthorized unless token

      token.touch_last_used
      @transport.call(env)
    end

    private

    def bearer_token(env)
      env["HTTP_AUTHORIZATION"].to_s[/\ABearer\s+(\S+)\z/i, 1]
    end

    def unauthorized
      [ 401,
        { "content-type" => "application/json", "www-authenticate" => 'Bearer realm="JobTrack"' },
        [ { error: "Missing or invalid API token" }.to_json ] ]
    end
  end
end
