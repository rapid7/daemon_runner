require 'mixlib/shellout'

module DaemonRunner
  class ShellOut
    attr_reader :runner, :stdout
    attr_reader :command, :cwd, :timeout

    # @param command [String] the command to run
    # @param cwd [String] the working directory to run the command
    # @param timeout [FixNum] the command timeout
    def initialize(command: nil, cwd: '/tmp', timeout: 15)
      @command = command
      @cwd = cwd
      @timeout = timeout
    end

    # Run command
    # @return [Mixlib::ShellOut] client
    def run!
      validate_args
      runner
      @runner.run_command
      @runner.error!
      @stdout = @runner.stdout
      @runner
    end

    private

    # @private
    # Validate arguments before trying to start the command
    # @ raise [ArgumentError] if any of the arguments are missing
    def validate_args
      if @command.nil? && !respond_to?(:command)
        raise ArgumentError, 'Must pass a command or implement a command method'
      end

      if @cwd.nil? && !respond_to?(:cwd)
        raise ArgumentError, 'Must pass a cwd or implement a cwd method'
      end

      if @timeout.nil? && !respond_to?(:timeout)
        raise ArgumentError, 'Must pass a timeout or implement a timeout method'
      end
    end

    # @private
    # Setup a new Mixlib::ShellOut client runner
    # @return [Mixlib::ShellOut] client
    def runner
      @runner ||= Mixlib::ShellOut.new(command, :cwd => cwd, :timeout => timeout)
    end


  end
end
