require 'logging'

module DaemonRunner
  #
  # Logging module
  #
  module Logger

    def logger_name
      STDOUT
    end

    def logger
      @logger ||= ::Logging.logger(logger_name)
    end
  end
end
