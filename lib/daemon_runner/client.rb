require 'logging'

module DaemonRunner
  class Client
    @@logger = Logging.logger(STDOUT)

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def logger
      @@logger
    end

    def wait
      'Must implement this in a subclass'
    end

    def tasks
      raise NotImplementedError, 'Must implement this in a subclass.  \
      This must be an array of method for the runner to call'
    end

    def loop_sleep_time
      return @loop_sleep_time unless @loop_sleep_time.nil?
      if options[:loop_sleep_time].nil?
        @loop_sleep_time = rand(5..10)
      else
        @loop_sleep_time = options[:loop_sleep_time]
      end
    end

    def error_sleep_time
      return @error_sleep_time unless @error_sleep_time.nil?
      if options[:error_sleep_time].nil?
        @error_sleep_time = 5
      else
        @error_sleep_time = options[:error_sleep_time]
      end
    end

    def start!
      wait if respond_to?(:wait)

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
