require_relative '../test_helper'

class MyFakeException < ArgumentError; end
class AnotherFakeException < ArgumentError; end

class RetryErrorsTest < Minitest::Test

  def test_can_pass

    retries = 1
    test = Proc.new {
      DaemonRunner::RetryErrors.retry(retries: 7, exceptions: [AnotherFakeException]) do
        loop do
          retries += 1
          if retries % 5 == 0
            return 0
          else
            raise AnotherFakeException
          end
        end
      end
    }
    assert_equal(test.call, 0)
  end

  def test_can_raise_exception
    assert_raises(MyFakeException) {
      DaemonRunner::RetryErrors.retry(exceptions: [MyFakeException]) do
        loop do
          raise MyFakeException, 'boom'
        end
      end
    }
  end
end
