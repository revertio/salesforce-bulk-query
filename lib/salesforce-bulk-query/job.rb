require 'nokogiri'

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

      res = @client.post("/job", xml, headers: {"Content-Type" => "application/xml; charset=UTF-8"})

      doc = Nokogiri::XML res
      @id = doc.css("id").text
    end

    def execute(query)
      res = @client.post("/job/#{id}/batch", query, headers: {"Content-Type" => "text/csv; charset=UTF-8"})

      doc = Nokogiri::XML res
      @batch_id = doc.css("id").text

      loop do
        case check_status
          when "Completed"
            return results

          when "Failed"
            raise "Bulk Job Failed Id: #{id}"

          else
            sleep(2)
        end
      end
    end

    def check_status
      res = @client.get("/job/#{id}/batch/#{@batch_id}")

      doc = Nokogiri::XML res
      doc.css("state").text
    end

    def results
      res = @client.get("/job/#{id}/batch/#{@batch_id}/result")

      doc = Nokogiri::XML res
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

