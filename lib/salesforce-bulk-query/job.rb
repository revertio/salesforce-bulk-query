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
      xml << "<contentType>CSV</contentType>"
      xml << "</jobInfo>"

      response = @client.post("/job", xml, headers: {"Content-Type" => "application/xml; charset=UTF-8"})

      doc = Nokogiri::XML response
      @id = doc.css("id").text
    end

    def execute(query)
      response = @client.post("/job/#{id}/batch", query, headers: {"Content-Type" => "text/csv; charset=UTF-8"})

      doc = Nokogiri::XML response
      @batch_id = doc.css("id").text

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
      doc = Nokogiri::XML response

      case doc.css("state").text
        when "Completed"
          return true
        when "Failed"
          raise JobError.new doc.css("stateMessage").text
        else
          return false
      end
    end

    def results
      response = @client.get("/job/#{id}/batch/#{@batch_id}/result")

      doc = Nokogiri::XML response
      doc.css("result").collect {|result| JobResult.new(@client, id, @batch_id, result.text)}
    end

    def get_result(result_id)
      @client.get("/job/#{id}/batch/#{@batch_id}/result/#{result_id}")
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
      res = @client.get("/job/#{@job_id}/batch/#{@batch_id}/result/#{@result_id}")
      CSV.parse(res, headers: true)
    end
  end

end

