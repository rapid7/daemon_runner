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
      This must be an array of methods for the runner to call'
    end

    # @return [Fixnum] Number of seconds to sleep between loop interations.
    def loop_sleep_time
      return @loop_sleep_time unless @loop_sleep_time.nil?
      @loop_sleep_time = options[:loop_sleep_time] || 5
    end

    # @return [Fixnum] Number of seconds to sleep before retrying an error
    def error_sleep_time
      return @error_sleep_time unless @error_sleep_time.nil?
      @error_sleep_time = options[:error_sleep_time] ||= 5
    end

    # @return [Fixnum] Number of seconds to sleep after each task
    def post_task_sleep_time
      return @post_task_sleep_time unless @post_task_sleep_time.nil?
      @post_task_sleep_time = options[:post_task_sleep_time] ||= 1
    end

    # Start the service
    # @return [nil]
    def start!
      wait

      loop do # Loop on tasks
        logger.warn 'Tasks list is empty' if tasks.empty?
        tasks.each do |task|
          run_task(task)
          sleep post_task_sleep_time
        end

        sleep loop_sleep_time
      end

    rescue StandardError => e
      # Don't exit the process if initialization fails.
      logger.error(e)

      sleep error_sleep_time
      retry
    end

    private

    # @private
    # @param [Array] task task to parse
    # @return [Array<String, String, Array>] task parsed in parts: Class, method, and arguments
    def parse_task(task)
      raise ArgumentError, 'Not enough elements in the Array' if task.length < 2
      out = {}
      out[:instance] = task[0]

      out[:class_name] = if out[:instance].class.to_s == 'Class'
                           out[:instance].name.to_s
                         else
                           out[:instance].class.to_s
                         end

      out[:method] = task[1]
      out[:args] = task[2..-1].flatten
      out
    end

    # @private
    # @param [Array<String, String, Array>] task to run
    # @return [String] output returned from task
    def run_task(task)
      parsed_task = parse_task(task)
      instance = parsed_task[:instance]
      class_name = parsed_task[:class_name]
      method = parsed_task[:method]
      args = parsed_task[:args]
      log_line = "Running #{class_name}.#{method}"
      log_line += "(#{args})" unless args.empty?
      logger.debug log_line

      out = if args.empty?
              instance.send(method.to_sym)
            else
              instance.send(method.to_sym, args)
            end
      logger.debug "Got: #{out}"
      out
    end
  end
end
