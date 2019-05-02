require 'simplecov'
require 'simplecov-console'
formatters = [SimpleCov::Formatter::HTMLFormatter,
              SimpleCov::Formatter::Console]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  formatters
)
SimpleCov.minimum_coverage 85 #TODO: make it 100 after proper tests are written
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'

def assert_warn(msg, &block)
  original_stderr = $stderr
  begin
    str = StringIO.new
    $stderr = str
    yield
    assert_equal msg, str.string
  ensure
    $stderr = original_stderr
  end
end
