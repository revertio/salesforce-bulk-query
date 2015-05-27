require 'httparty'
require 'retriable'

module SalesforceBulkQuery
  class Client
    include HTTParty

    API_VERSION = "33.0"

    def initialize(client_id, client_secret, refresh_token)
      @connection = SalesforceBulkQuery::Connection.new(client_id, client_secret, refresh_token)
      @connection.authorize!
    end

    def query(object_type, query)
      job = SalesforceBulkQuery::Job.new(self, "Contact")
      job.execute(query)
    end

    def post(url, payload, options={})
      headers = options[:headers] || {}

      retriable do
        options = {
          body: payload,
          headers: request_headers.merge(headers)
        }

        response = self.class.post(service_url(url), options)
        parse_for_errors response.body
      end
    end

    def get(url)
      retriable do
        response = self.class.get(service_url(url), { headers: request_headers })
        parse_for_errors response.body
      end
    end

    def retriable
      do_this_on_each_retry = -> (exception, tries) do
        if exception.is_a? AuthorizationError
            # If its an auth error attempt to reauth
            @connection.authorize!
        end
      end

      ::Retriable.retriable tries: 4,
        interval: -> (n) { n ** 2.5},
        on_retry: do_this_on_each_retry do
          yield
        end
    end

    private

    def service_url(url)
      "#{@connection.instance_url}/services/async/#{API_VERSION}#{url}"
    end

    def request_headers
      headers = Hash.new
      headers["X-SFDC-Session"] = @connection.session_id
      headers
    end

    def parse_for_errors(response)
      body = Nokogiri::XML response

      errors = body.css("error")

      unless errors.empty?
        code = errors.css("exceptionCode").text
        message = errors.css("exceptionMessage").text

        if code == "InvalidSessionId"
          raise AuthorizationError.new(message)
        else
          raise GeneralError.new(message)
        end
      end

      response
    end

  end

end