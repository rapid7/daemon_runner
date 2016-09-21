require 'logging'

module DaemonRunner
  class Client

    # @attribute [r]
    # Options hash
    attr_reader :options, :logger

    # @attribute [r]
    # Logger instance
    attr_reader :logger

    def initialize(options, logger = STDOUT)
      @options = options
      @logger = Logging.logger(logger)
    end

    # Hook to allow initial setup tasks before running tasks.
    # @abstract Override {#wait} to pause before starting.
    # @return [void]
    def wait
    end

    # List of tasks that get executed in {#start!}
    # @abstract Override {#tasks} in a subclass.
    # @return [Array<Array>]
    # @example Example tasks method
    #    def tasks
    #      [
    #        [::MyService::Tasks::Foo.new, 'run!'],
    #        [::MyService::Tasks::Bar.new, 'run!', 'bar'],
    #        [::MyService::Tasks::Baz, 'run!', 'baz', 'because']
    #      ]
    #    end
    def tasks
      raise NotImplementedError, 'Must implement this in a subclass.  \
      This must be an array of method for the runner to call'
    end

    # @return [Fixnum] Number of seconds to sleep between loop interations.
    def loop_sleep_time
      return @loop_sleep_time unless @loop_sleep_time.nil?
      if options[:loop_sleep_time].nil?
        @loop_sleep_time = rand(5..10)
      else
        @loop_sleep_time = options[:loop_sleep_time]
      end
    end

    # @return [Fixnum] Number of seconds to sleep before retrying an error
    def error_sleep_time
      return @error_sleep_time unless @error_sleep_time.nil?
      if options[:error_sleep_time].nil?
        @error_sleep_time = 5
      else
        @error_sleep_time = options[:error_sleep_time]
      end
    end

    # Start the service
    # @return [nil]
    def start!
      wait

      loop do # Loop on tasks
        logger.warn 'Tasks list is empty' if tasks.empty?
        tasks.each do |task|
          instance = task[0]
          method = task[1]
          args = task[2..-1].flatten
          if args.empty?
            logger.debug "Running #{instance.class}.#{method}"
            out = instance.send(method.to_sym)
          else
            logger.debug "Running #{instance.class}.#{method}(#{args})"
            out = instance.send(method.to_sym, args)
          end
          logger.debug "Got: #{out}"
          sleep 1
        end

        sleep loop_sleep_time
      end

    rescue StandardError => e
      # Don't exit the process if initialization fails.
      logger.error(e)

      sleep error_sleep_time
      retry
    end
  end
end
