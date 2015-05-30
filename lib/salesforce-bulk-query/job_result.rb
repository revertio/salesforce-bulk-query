module SalesforceBulkQuery
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

      unless response["queryResult"].nil?
        records = response["queryResult"]["records"]
      end

      records || []
    end
  end
end