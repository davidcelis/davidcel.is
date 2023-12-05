module Errors
  class BadRequest < StandardError
    attr_reader :original_exception, :status_code

    def initialize(msg = "Bad Request", original_exception: nil)
      super(msg)

      @original_exception = original_exception
      @status_code = 400
    end
  end
end
