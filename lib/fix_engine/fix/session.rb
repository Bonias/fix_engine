require 'libxml'

class FIX
  class Schema
    def initialize(schema)
      file = schema
      file = File.dirname(__FILE__) + "/" + schema unless File.exists?(file)
      file = File.dirname(__FILE__) + "/../" + schema unless File.exists?(file)
      riase ArgumentError, "Can't load file for schema: #{schema}" unless File.exists?(file)
      @file = file
    end

    def document
      @document ||= LibXML::XML::Document.file(@file)
    end

    def fields
      @fields ||= document.find('//fields')[0]
    end

    def field(name_or_identifier)
      @_field ||= {}
      @_field[name_or_identifier] ||= begin
        if name_or_identifier.is_a?(Fixnum) || name_or_identifier =~ /^\d+$/
          fields.find("field[@number=\"#{name_or_identifier}\"]")[0]
        else
          fields.find("field[@name=\"#{name_or_identifier}\"]")[0]
        end
      end
    end

    def messages
      @messages = document.find('//messages')[0]
    end

    def message(name)
      @_message ||= {}
      @_message[name] ||= messages.find("message[@name=\"#{name}\"]")[0]
    end

    def header
      @header ||= document.find('//header')[0]
    end

    def header_fields
      @header_fields ||= header.find('field')
    end

    def required_header_fields
      @required_header_fields ||= header.find('field[@required="Y"]')
    end
  end

  # Fix Session protocol class
  # Created to parse XML schema that describes possible messages.
  # That helps to validate outgoing messages
  class Session
    attr_reader :schema
    attr_accessor :begin_string, :properties

    def initialize(begin_string, schema)
      @schema = schema.is_a?(Schema) ? schema : Schema.new(schema)

      @begin_string = begin_string
      @properties = {'MsgSeqNum' => 1}
    end
  end
end