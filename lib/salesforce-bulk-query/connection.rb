require 'oauth2'

module SalesforceBulkQuery
  class Connection

    attr_accessor :instance_url, :session_id

    def initialize(client_id, client_secret, refresh_token)
      @id = client_id
      @secret = client_secret
      @refresh_token = refresh_token
      @site = "https://login.salesforce.com" # "https://test.salesforce.com" for sandbox
    end

    def session_id
      @token.token
    end

    def instance_url
      @token.params["instance_url"]
    end

    def authorize!
      access_token = OAuth2::AccessToken.new(oauth_client, nil, { refresh_token: @refresh_token })

      @token = access_token.refresh!
    rescue OAuth2::Error => e
      raise AuthorizationError.new e
    end

    private

    def oauth_client
      @client ||= OAuth2::Client.new(@id, @secret, site: @site, token_url: "services/oauth2/token?grant_type=refresh_token")
    end

  end
end