require 'fix_engine'

require 'test/unit'

class FixResponseTest < Test::Unit::TestCase
  def test_initialize()
    assert_raise(ArgumentError) { FIX::Response.new }
    session = FIX::Session.new("FIX.4.2", "etc/FIX42.xml")
    assert_raise(ArgumentError) { FIX::Response.new(session) }
    assert_nothing_raised(ArgumentError) { FIX::Response.new(session, "") }
    assert_nothing_raised(ArgumentError) { FIX::Response.new(session, "").response }
    assert_equal(0, FIX::Response.new(session, "").response.size)
    assert_equal(1, FIX::Response.new(session, "8=76").response.size)
    assert_equal("76", FIX::Response.new(session, "8=76").response['BeginString'])
    assert_equal("hello", FIX::Response.new(session, "8=76\x0156=hello").response['TargetCompID'])
    assert_equal("hello", FIX::Response.new(session, "8=76\x01156=hello").response['SettlCurrFxRateCalc'])
    assert_equal(["hello", "world", "eoln"], FIX::Response.new(session, "8=76\x0133=3\x0158=hello\x0158=world\x0158=eoln").response['Text'])
    assert_equal("3", FIX::Response.new(session, "8=76\x01556646=3").response['556646'])
    assert_equal(["3", "hello"], FIX::Response.new(session, "8=76\x01556646=3\x01556646=hello").response['556646'])
  end
end
