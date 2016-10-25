require 'retryable'

module DaemonRunner
    #
    # Retry Errors
    #
    class RetryErrors
      class << self
        def retry(retries: 3, exceptions: [Faraday::ClientError], &block)
          Retryable.retryable({
            on: exceptions,
            sleep: lambda { |c| 2 ** c * 0.3 },
            tries: retries}) do |retries, exception|
              block.call
          end
        end
      end
    end
  end
