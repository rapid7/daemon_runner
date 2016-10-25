require 'retryable'

module DaemonRunner
    #
    # Retry Errors
    #
    class RetryErrors
      extend Logger

      class << self
        def retry(retries: 3, exceptions: [Faraday::ClientError], &block)
          properties = {
            on: exceptions,
            sleep: lambda { |c| 2**c * 0.3 },
            tries: retries
          }
          Retryable.retryable(properties) do |retries, exception|
            logger.warn "try #{retries} failed with exception: #{exception}" if retries > 0
            block.call
          end
        end
      end
    end
  end
