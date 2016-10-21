#!/usr/bin/env ruby

require_relative '../lib/daemon_runner'

class MyService
  class Tasks
    class Foo
      def run!
        puts 'foo'
        'foo'
      end
    end
  end
end

class MyService
  class Tasks
    class Bar
      def schedule
        [:cron, '*/1 * * * *']
      end

      def run!(name)
        puts name
        name
      end
    end
  end
end

class MyService
  class Tasks
    class Baz
      class << self
        def schedule
          [:interval, 10]
        end

        def run!(args)
          name = args[0]
          reason = args[1]
          puts name
          puts reason
          name
        end
      end
    end
  end
end

class MyService
  class Tasks
    class Quiz
      def schedule
        [:interval, '30s']
      end
      def foo!(args)
        puts 'Firing error'
        sargs
      end
    end
  end
end

class MyService
  class Client < DaemonRunner::Client
    def tasks
      [
        [::MyService::Tasks::Foo.new, 'run!'],
        [::MyService::Tasks::Bar.new, 'run!', 'bar'],
        [::MyService::Tasks::Baz, 'run!', 'baz', 'because'],
        [::MyService::Tasks::Quiz.new, 'foo!', 'blarg', 'assdg']
      ]
    end
  end
end

options = {}
service = MyService::Client.new(options)
service.start!
