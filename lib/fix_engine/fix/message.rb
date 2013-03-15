class FIX::Message

  class Field
    attr_accessor :name, :identifier, :value, :schema

    def initialize(schema, name_or_identifier, value)
      if name_or_identifier.is_a?(Fixnum) || name_or_identifier =~ /^\d+$/
        @identifier = name_or_identifier.to_s
      else
        @name = name_or_identifier
      end
      @value = value
      @schema = schema
    end

    def identifier
      @identifier ||= begin
        if el_field = schema.field(@name)
          el_field.attributes['number']
        else
          raise "No field '#{@name}' in schema."
        end
      end
    end

    def name
      @name ||= begin
        if el_field = schema.field(@identifier)
          el_field.attributes['name']
        else
          raise "No field '#{@identifier}' in schema."
        end
      end
    end

    def to_s
      "#{identifier}=#{value}"
    end
  end

  SEP = "\01".freeze

  attr_accessor :session

  def schema
    session.schema
  end

  def initialize(session, msg_type, extra_fields = {})
    @session = session
    @begin_string = session.begin_string
    @fields_mapping = {}
    @fields = []
    @msg_def = nil

    # process msg_type
    if @msg_def = schema.message(msg_type)
      @msg_type = @msg_def.attributes['msgtype']
    else
      @msg_def = nil ## TODO: fix this ##
      @msg_type = msg_type
    end

    extra_fields.each_pair do |key, value|
      self.add_field(key, value)
    end
  end

  def reset(hard=false)
    @value = nil
    @sending_time_filed_added = false

    if hard
      @required_header_fields_added = false
      @message_definition_fields_added = false
    end
  end

  def add_required_header_fields
    return if @required_header_fields_added
    @required_header_fields_added = true

    schema.required_header_fields.each do |el|
      if !['BeginString', 'BodyLength', 'MsgType', 'SendingTime'].include?(el.attributes['name'])
        if session.properties.has_key?(el.attributes['name'])
          self.add_field(el.attributes['name'], session.properties[el.attributes['name']])
        else
          raise "Field '#{el.attributes['name']}' required by message type #{@msg_type}, but could not locate data."
        end
      end
    end
  end

  def add_sending_time_filed
    return if @sending_time_filed_added
    @sending_time_filed_added = true

    # sending time
    #self.add_field('SendingTime', Time.new.utc.strftime('%Y%m%d-%H:%M:%S.%3N')) # ruby 1.9 only
    t = Time.new.utc # the following is ruby 1.8-compatible:
    tf = t.to_f
    milliseconds = ((tf - tf.floor) * 1000).round.to_s.ljust(3, '0')
    self.add_field('SendingTime', t.strftime("%Y%m%d-%H:%M:%S.#{milliseconds}"))
  end

  def add_message_definition_fields
    return if @message_definition_fields_added
    @message_definition_fields_added = true

    return unless @msg_def

    @msg_def.find('field[@required="Y"]').each do |el|
      if session.properties.has_key?(el.attributes['name'])
        self.add_field(el.attributes['name'], session.properties[el.attributes['name']])
      else
        raise "Field '#{el.attributes['name']}' required by message type #{@msg_type}, but could not locate data."
      end
    end
  end

  def to_s
    value
  end

  def value
    @value ||= begin
      add_required_header_fields
      add_sending_time_filed
      add_message_definition_fields

      msg_to_string
    end
  end

  def add_field(name, value)
    field = Field.new(schema, name, value)
    if position = @fields_mapping[field.identifier]
      @fields[position] = field # replace existing field
    else
      @fields << field
      @fields_mapping[field.identifier] = @fields.size - 1
    end

    return self
  end

  def self.checksum(str)
    i = 0
    str.each_byte do |b|
      i += b # unless b == 1
    end
    (i % 256).to_s.rjust(3, '0')
  end

  protected

  def msg_to_string
    msg_body_str = msg_body
    msg_str = "8=#{@begin_string}" << SEP
    msg_str << "9=#{msg_body_str.length}" << msg_body_str << SEP
    msg_str << checksum_field(msg_str) << SEP
  end

  def msg_body
    "".tap do |str|
      str << SEP + "35=#{@msg_type}" + SEP + @fields.map(&:to_s).join(SEP)
    end
  end

  def checksum_field(str)
    "10=#{self.class.checksum(str)}"
  end
end

