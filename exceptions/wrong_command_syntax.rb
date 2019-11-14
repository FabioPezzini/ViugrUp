# frozen_string_literal: true

class WrongCommandSyntax < StandardError
  def initialize(message)
    err_msg = 'ERROR: ' + message + ', type help for more info'
    super(err_msg)
  end
end
