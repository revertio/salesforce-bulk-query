module SalesforceBulkQuery
  class Client

    attr_accessor :logger

    API_VERSION = "33.0"

    def initialize(client_id, client_secret, refresh_token, options={})
      @logger = options[:logger] || Logger.new($stderr)
      @connection = SalesforceBulkQuery::Connection.new(client_id, client_secret, refresh_token)
      @connection.authorize!
    end

    def query(object_type, query)
      logger.debug "[SALESFORCE_BULK_QUERY] QUERY #{object_type} : #{query}"

      job = SalesforceBulkQuery::Job.new(self, object_type)
      job.execute(query)
    end

    def post(url, payload, options={})
      logger.debug "[SALESFORCE_BULK_QUERY] POST #{url}"

      headers = options[:headers] || {}

      retriable do
        options = {
          body: payload,
          headers: request_headers.merge(headers)
        }

        response = HTTParty.post(service_url(url), options)
        parse_for_errors response.parsed_response
      end
    end

    def get(url)
      logger.debug "[SALESFORCE_BULK_QUERY] GET #{url}"

      retriable do
        response = HTTParty.get(service_url(url), { headers: request_headers })
        parse_for_errors response.parsed_response
      end
    end

    def retriable
      do_this_on_each_retry = -> (exception, tries) do
        logger.debug "[SALESFORCE_BULK_QUERY] Retry request. Tries: #{tries}"

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
      if response.has_key? "error"
        code = response["error"]["exceptionCode"]
        message = response["error"]["exceptionMessage"]

        if code == "InvalidSessionId"
          raise AuthorizationError.new message
        else
          raise TransmissionError.new message
        end
      end

      response
    end

  end

end