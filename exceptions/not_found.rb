class NotFound < StandardError
  def initialize(message)
    err_msg = 'ERROR: ' + message
    super(err_msg)
  end
end
