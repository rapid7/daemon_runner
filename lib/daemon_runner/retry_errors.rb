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
            sleep: lambda { |c| Kernel.sleep(2 ** retries * 0.3) }},
            &block
          )
        end
      end
    end
  end
