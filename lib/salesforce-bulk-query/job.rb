module SalesforceBulkQuery
  class Job

    # Public: the id of the Job. Assigned when we `create` the Job
    # on SalesForce.
    attr_accessor :id
    # Public: batch_id is assigned when SalesForce begins executing the Job.
    attr_accessor :batch_id
    # Public: The results of the Job.
    attr_accessor :results


    def initialize(client, object_type)
      @client = client
      @object_type = object_type
      create
    end

    def create
      xml =  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      xml << "<jobInfo xmlns=\"http://www.force.com/2009/06/asyncapi/dataload\">"
      xml << "<operation>query</operation>"
      xml << "<object>#{@object_type}</object>"
      xml << "<concurrencyMode>Parallel</concurrencyMode>"
      xml << "<contentType>XML</contentType>"
      xml << "</jobInfo>"

      response = @client.post("/job", xml, headers: {"Content-Type" => "application/xml; charset=UTF-8"})

      @id = response["jobInfo"]["id"]
    end

    def execute(query)
      require_id
      response = @client.post("/job/#{id}/batch", query, headers: {"Content-Type" => "application/xml; charset=UTF-8"})

      @batch_id = response["batchInfo"]["id"]

      wait_for_results
    end

    def wait_for_results(sleep_time=2)
      loop do
        if completed?
          return get_results
        else
          sleep sleep_time
        end
      end
    end

    def completed?
      require_id && require_batch_id

      response = @client.get("/job/#{id}/batch/#{batch_id}")

      case response["batchInfo"]["state"]
      when "Completed"
        return true
      when "Failed"
        raise JobError.new response["batchInfo"]["stateMessage"]
      else
        return false
      end
    end

    # Public: Will GET and parse results from a completed Job.
    # Assigns the results to the `results` attribute.
    # Returns the results.
    def get_results
      require_id && require_batch_id

      response = @client.get("/job/#{id}/batch/#{batch_id}/result")

      results = []
      results << response["result_list"]["result"]

      @results = results.flatten.map do |result_id|
        JobResult.new(@client, id, batch_id, result_id)
      end
    end

    private
      def require_id
        raise ArgumentError, "`id` required. Have you run `create`?" unless id
      end

      def require_batch_id
        raise ArgumentError, "`batch_id` required. Have you run `execute`?" unless batch_id
      end

  end

  class JobResult
    attr_accessor :records

    def initialize(client, job_id, batch_id, result_id)
      @client = client
      @job_id = job_id
      @batch_id = batch_id
      @result_id = result_id
    end

    def records
      response = @client.get("/job/#{@job_id}/batch/#{@batch_id}/result/#{@result_id}")
      response["queryResult"]["records"]
    end
  end

end

