require_relative '../lib/wavefrontopentracing/reporting/wavefront'
require 'test_helper'

class WavefrontSpanReporterTest < Minitest::Test
  def test_create
    reporter = Reporting::WavefrontSpanReporter.new(client: self, source: nil)
    assert reporter
  end
  def test_report
    reporter = Reporting::WavefrontSpanReporter.new(client: self, source: nil)
  end
end
