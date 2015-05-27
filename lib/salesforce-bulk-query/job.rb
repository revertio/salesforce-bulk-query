module SalesforceBulkQuery
  class Job

    attr_accessor :id

    def initialize(client, object_type)
      @client = client

      create_job(object_type)
    end

    def create_job(object_type)
      xml =  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      xml << "<jobInfo xmlns=\"http://www.force.com/2009/06/asyncapi/dataload\">"
      xml << "<operation>query</operation>"
      xml << "<object>#{object_type}</object>"
      xml << "<concurrencyMode>Parallel</concurrencyMode>"
      xml << "<contentType>XML</contentType>"
      xml << "</jobInfo>"

      response = @client.post("/job", xml, headers: {"Content-Type" => "application/xml; charset=UTF-8"})

      @id = response["jobInfo"]["id"]
    end

    def execute(query)
      response = @client.post("/job/#{id}/batch", query, headers: {"Content-Type" => "application/xml; charset=UTF-8"})

      @batch_id = response["batchInfo"]["id"]

      loop do
        if job_completed
          return results
        else
          sleep(2)
        end
      end
    end

    def job_completed
      response = @client.get("/job/#{id}/batch/#{@batch_id}")

      case response["batchInfo"]["state"]
        when "Completed"
          return true
        when "Failed"
          raise JobError.new response["batchInfo"]["stateMessage"]
        else
          return false
      end
    end

    def results
      response = @client.get("/job/#{id}/batch/#{@batch_id}/result")

      results = []
      results << response["result_list"]["result"]

      results.flatten.map do |result_id|
        JobResult.new(@client, id, @batch_id, result_id)
      end
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
      @client.get("/job/#{@job_id}/batch/#{@batch_id}/result/#{@result_id}")
    end
  end

end

