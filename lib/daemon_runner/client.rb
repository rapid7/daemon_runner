require 'rufus-scheduler'

module DaemonRunner
  class Client
    include Logger

    # @attribute [r]
    # Options hash
    attr_reader :options


    def initialize(options)
      @options = options

      # Set error handling
      # @param [Rufus::Scheduler::Job] job job that raised the error
      # @param [RuntimeError] error the body of the error
      def scheduler.on_error(job, error)
        error_sleep_time = job[:error_sleep_time]
        logger = job[:logger]

        logger.error(error)
        logger.debug "Suspending #{job.id} for #{error_sleep_time} seconds"
        job.pause
        sleep error_sleep_time
        logger.debug "Resuming #{job.id}"
        job.resume
      end
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

    # @return [Array<Symbol, String/Fixnum>] Schedule tuple-like with the type of schedule and its timing.
    def schedule
      # The default type is an `interval` which trigger, execute and then trigger again after
      # the interval has elapsed.
      [:interval, loop_sleep_time]
    end

    # @return [Fixnum] Number of seconds to sleep between loop interactions.
    def loop_sleep_time
      return @loop_sleep_time unless @loop_sleep_time.nil?
      @loop_sleep_time = if options[:loop_sleep_time].nil?
                           5
                         else
                           options[:loop_sleep_time]
                         end
    end

    # @return [Fixnum] Number of seconds to sleep before retrying an error
    def error_sleep_time
      return @error_sleep_time unless @error_sleep_time.nil?
      @error_sleep_time = if options[:error_sleep_time].nil?
                            5
                          else
                            options[:error_sleep_time]
                          end
    end

    # @return [Fixnum] Number of seconds to sleep after each task
    def post_task_sleep_time
      return @post_task_sleep_time unless @post_task_sleep_time.nil?
      @post_task_sleep_time = if options[:post_task_sleep_time].nil?
                                1
                              else
                                options[:post_task_sleep_time]
                              end
    end

    # Start the service
    # @return [nil]
    def start!
      wait

      logger.warn 'Tasks list is empty' if tasks.empty?
      tasks.each do |task|
        run_task(task)
        sleep post_task_sleep_time
      end

      scheduler.join
    rescue SystemExit, Interrupt
      logger.info 'Shutting down'
      scheduler.shutdown
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
    # @param [Class] instance an instance of the task class
    # @return [Hash<Symbol, String>] schedule parsed in parts: Schedule type and timing
    def parse_schedule(instance)
      valid_types = [:in, :at, :every, :interval, :cron]
      out = {}
      task_schedule = if instance.respond_to?(:schedule)
        instance.send(:schedule)
      else
        schedule
      end

      raise ArgumentError, 'Malformed schedule definition, should be [TYPE, DURATION]' if task_schedule.length < 2
      raise ArgumentError, 'Invalid schedule type' unless valid_types.include?(task_schedule[0].to_sym)

      out[:type] = task_schedule[0].to_sym
      out[:schedule] = task_schedule[1]
      out
    end

    # @private
    # @param [Array<String, String, Array>] task to run
    # @return [String] output returned from task
    def run_task(task)
      parsed_task = parse_task(task)
      instance = parsed_task[:instance]
      schedule = parse_schedule(instance)
      class_name = parsed_task[:class_name]
      method = parsed_task[:method]
      args = parsed_task[:args]

      # Schedule the task
      schedule_log_line = "Scheduling job #{class_name}.#{method} as #{schedule[:type]} type"
      schedule_log_line += " with interval #{schedule[:schedule]}"
      logger.debug schedule_log_line

      scheduler.send(schedule[:type], schedule[:schedule], :overlap => false, :job => true) do |job|
        log_line = "Running #{class_name}.#{method}"
        log_line += "(#{args})" unless args.empty?
        logger.debug log_line

        job[:error_sleep_time] = error_sleep_time
        job[:logger] = logger

        out = if args.empty?
          instance.send(method.to_sym)
        else
          instance.send(method.to_sym, args)
        end
        logger.debug "Got: #{out}"
      end
    end

    # @return [Rufus::Scheduler] A scheduler instance
    def scheduler
      @scheduler ||= ::Rufus::Scheduler.new
    end
  end
end
