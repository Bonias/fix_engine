require 'libxml'

# Fix Session protocol class
# Created to parse XML schema that describes possible messages.
# That helps to validate outgoing messaages
class FIX::Session
  attr_reader :schema, :schema_fields
  attr_accessor :begin_string, :properties

  def initialize(begin_string, schema)
	old_schema = schema
	schema = File.dirname(__FILE__) + "/" + schema if (!File.exists?( schema ))
	schema = File.dirname(__FILE__) + "/../" + old_schema if (!File.exists?( schema ))
    parser = LibXML::XML::Parser.file(schema)
    @schema = parser.parse

    @schema_fields = @schema.find('//fields')

    @begin_string = begin_string
    @properties = { 'MsgSeqNum' => 1 }
  end
end

