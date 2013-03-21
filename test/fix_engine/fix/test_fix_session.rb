require 'fix_engine'

require 'test/unit'

class FixSessionTest < Test::Unit::TestCase
  def test_initialize()
    assert_raise(ArgumentError) { FIX::Session.new }
    assert_nothing_raised(ArgumentError) { FIX::Session.new("FIX.4.2", "etc/FIX42.xml") }
    session = FIX::Session.new("FIX.4.2", "etc/FIX42.xml")
    assert_equal(1, session.properties.size)
    assert_equal(1, session.properties['MsgSeqNum'])
    assert_equal("FIX.4.2", session.begin_string)
    assert_equal(FIX::Schema, session.schema.class)
  end
end
