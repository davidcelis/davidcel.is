class ErrorsController < ApplicationController
  SUPPORTED_ERROR_CODES = {
    404 => "not_found",
    500 => "internal_server_error"
  }.freeze

  def show
    Sentry.capture_exception(exception) if status_code >= 500

    respond_to do |format|
      format.html { render view_for_code(status_code), status: status_code }
      format.all { head status_code }
    end
  end

  private

  def view_for_code(code)
    SUPPORTED_ERROR_CODES.fetch(code, "not_found")
  end

  def exception
    request.env["action_dispatch.exception"]
  end

  def status_code
    exception.try(:status_code) || ActionDispatch::ExceptionWrapper.new(request.env, exception).status_code
  end
end
