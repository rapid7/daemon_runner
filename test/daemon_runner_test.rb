require_relative 'test_helper'

class MyService; end
class MyService::Tasks; end
class MyService::Tasks::Foo; end
class MyService::Tasks::Bar; end
class MyService::Tasks::Baz; end
class MyService::Tasks::Quiz
  def schedule
    [:every, 10]
  end
end
class MyService::Tasks::InvalidSched
  def schedule
    [:thiswontwork, 25]
  end
end

class TestDaemonRunner < ::DaemonRunner::Client
end

class DaemonRunnerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DaemonRunner::VERSION
  end

  def test_parsed_task_can_get_class_name
    runner = TestDaemonRunner.new({})
    task = [::MyService::Tasks::Foo.new, 'run!']
    parsed_task = runner.send(:parse_task, task)
    assert_equal 'MyService::Tasks::Foo',
                 parsed_task[:class_name]
  end

  def test_parsed_task_can_get_module_name
    runner = TestDaemonRunner.new({})
    task = [::MyService::Tasks::Foo, 'run!']
    parsed_task = runner.send(:parse_task, task)
    assert_equal 'MyService::Tasks::Foo',
                 parsed_task[:class_name]
  end

  def test_parsed_task_can_get_method_name
    runner = TestDaemonRunner.new({})
    task = [::MyService::Tasks::Foo, 'run!']
    parsed_task = runner.send(:parse_task, task)
    assert_equal 'run!', parsed_task[:method]
  end

  def test_parsed_task_can_get_args
    runner = TestDaemonRunner.new({})
    task1 = [::MyService::Tasks::Foo, 'run!', 'foo']
    parsed_task1 = runner.send(:parse_task, task1)
    assert_equal ['foo'], parsed_task1[:args]

    task2 = [::MyService::Tasks::Foo, 'run!', 'foo', 'bar']
    parsed_task2 = runner.send(:parse_task, task2)
    assert_equal ['foo', 'bar'], parsed_task2[:args]
  end

  def test_parsed_task_has_default_schedule
    runner = TestDaemonRunner.new({})
    task = [::MyService::Tasks::Foo.new, 'run!', 'foo']
    parsed_task = runner.send(:parse_task, task)
    parsed_schedule = runner.send(:parse_schedule, parsed_task[:instance])
    expected = {:type => :interval, :schedule => 5}
    assert_equal expected, parsed_schedule
  end

  def test_parsed_task_can_provide_schedule
    runner = TestDaemonRunner.new({})
    task = [::MyService::Tasks::Quiz.new, 'run!', 'foo']
    parsed_task = runner.send(:parse_task, task)
    parsed_schedule = runner.send(:parse_schedule, parsed_task[:instance])
    expected = {:type => :every, :schedule => 10}
    assert_equal expected, parsed_schedule
  end

  def test_parsed_task_errors_if_invalid_schedule_type
    runner = TestDaemonRunner.new({})
    task = [::MyService::Tasks::InvalidSched.new, 'run!', 'foo']
    parsed_task = runner.send(:parse_task, task)
    err = assert_raises ArgumentError do
      runner.send(:parse_schedule, parsed_task[:instance])
    end
    assert_match /Invalid schedule type/, err.message
  end
end
