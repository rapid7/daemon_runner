# DaemonRunner

This is a library that will assist you in writing long running services that are composed of discrete tasks.  For example you may want to check that a service is running, or run some command and send it's output somewhere.

The basic design consists of a list of tasks that loop forever.  The user is responsible to defining what those tasks are and what they do in a subclass.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'daemon_runner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install daemon_runner

## Usage

In order to use this gem you must subclass `DaemonRunner::Client` and add a few methods:

* `tasks` - This is an array of tasks to run (**required**)

```ruby
[
  [ClassName1, method_name, args],
  [ClassName2, method_name, args]
]
  ```

* `wait` - Setup hook to run before starting tasks (**optional**)

* `options` - Options hash to pass to `initialize` (**required**)
    * :loop_sleep_time - Number of seconds to sleep before starting tasks again (**optional**, _default_: 5 seconds)
    * :error_sleep_time - Number of seconds to sleep before retying a failed task (**optional**, _default_: 5 seconds)
    * :post_task_sleep_time - Number of seconds to sleep after each task (**optional**, _default_: 1 seconds)

* `schedule` - How often the task should run. See [Scheduling](#scheduling) below. (**optional**)

### Example

```ruby
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
  class Client < DaemonRunner::Client
    def tasks
      [
        [::MyService::Tasks::Foo.new, 'run!'],
        [::MyService::Tasks::Bar.new, 'run!', 'bar'],
        [::MyService::Tasks::Baz, 'run!', 'baz', 'because']
      ]
    end
  end
end

options = {}
service = MyService::Client.new(options)
service.start!
```

### Scheduling
Tasks can define the schedule that they run on and how their schedule is executed.
To do this, define a method named `schedule` with an array formatted as:

```ruby
  [:schedule_type, duration]
```

For example, if you wanted your task to run every 5 minutes, you would do the
following:

```ruby
#!/usr/bin/env ruby

class MyService
  class Tasks
    class Quiz
      def schedule
        [:every, '5m']
      end

      def run!(args)
        puts args
        args
      end
    end
  end
end
```

This would execute the `run!` method every 5 minutes. Duration can be defined as a
string in the `'<number>s/m/h/d/w'` format or as a number of seconds. Schedule types
are `:in, :at, :every, :cron, :interval`. See rufus-scheduler's
[README](https://github.com/jmettraux/rufus-scheduler#in-at-every-interval-cron)
for more information.

The default for tasks that don't explicitly define a schedule is

```ruby
def schedule
  [:interval, options[:loop_sleep_time]]
end
```

### Retries
Simple interface to retry requests that are known to fails sometimes.  To add a retry wrap the code like this:

```
DaemonRunner::RetryErrors.retry do
  my_not_so_good_network_service_that_fails_sometimes
end
```

* `options` - Options hash to pass to `retry` (**optional**)
    * :retries - Number of times to retry an exception (**optional**, _default_: 3)
    * :exceptions - Array of exceptions to catch and retry (**optional**, _default_: `[Faraday::ClientError]`)

### Locking
Locking can be done either via an exclusive lock or a semaphore lock.  The major difference is that with a semaphore lock you can define how many nodes can obtain the lock.

#### Exclusive Lock
**TBD**

#### Semaphore Lock
For an example of how to implement semaphore locking take a look at the [manual locking example](/examples/example_semaphore.rb) and the [slightly more automatic version](/examples/example_semaphore_release.rb).


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rapid7/daemon_runner. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
