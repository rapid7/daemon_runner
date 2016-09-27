require 'mixlib/shellout'

module DaemonRunner
  class ShellOut
    attr_reader :runner, :stdout

    def cwd
      '/tmp'
    end

    def timeout
      15
    end

    def runner
      @runner ||= Mixlib::ShellOut.new(command, :cwd => cwd, :timeout => timeout)
    end

    def run!
      runner
      @runner.run_command
      @runner.error!
      @stdout = @runner.stdout
      @runner
    end
  end
end
