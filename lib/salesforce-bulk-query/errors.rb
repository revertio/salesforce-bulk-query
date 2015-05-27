module SalesforceBulkQuery

  #
  # An exception that is raised if we have an unknown error communicating with Salesforce
  #
  class TranmissionError < StandardError
  end

  #
  # An exception that is raised if authorization with Salesforce fails
  #
  class AuthorizationError < StandardError
  end

  #
  # An exception that is raised if a job fails
  #
  class JobError < StandardError
  end

end