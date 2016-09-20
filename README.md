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

`[[_class_instance1_, _method_], [_class_instance2_, _method_]]`

* `wait` - Setup hook to run before starting tasks (**optional**)

* `options` - Options hash to pass to `initialize` (**required**)
    * :loop_sleep_time - Number of seconds to sleep before starting tasks again (**optional**, _default_: `5-10` seconds)
    * :error_sleep_time - Number of seconds to sleep before retying a failed task (**optional**, _default_: 5 seconds)

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
        def run!(name)
          puts name
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
        [::MyService::Tasks::Baz, 'run!', 'baz']
      ]
    end
  end
end

options = {}
service = MyService::Client.new(options)
service.start!
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rapid7/daemon_runner. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
