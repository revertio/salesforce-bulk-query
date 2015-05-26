require 'httparty'
require 'salesforce-bulk-query/job'
require 'salesforce-bulk-query/connection'

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

      job.execute("SELECT Id, Name FROM Contact")
    end

    def post(url, payload, options={})
      headers = options[:headers] || {}

      options = {
        body: payload,
        headers: request_headers.merge(headers)
      }

      self.class.post(service_url(url), options).body
    end

    def get(url)
      self.class.get(service_url(url), { headers: request_headers }).body
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

  end
end