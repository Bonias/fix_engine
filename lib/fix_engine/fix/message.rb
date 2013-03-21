class FIX::Message

  class FieldsList
    include Enumerable

    def initialize
      @fields = []
      @mapping_identifiers = {}
      @mapping_names = {}
    end

    def <<(field)
      position = @mapping_identifiers[field.identifier] || @mapping_names[field.name]
      if position
        @fields[position] = field
      else
        @fields << field
        position = @fields.length - 1
        @mapping_identifiers[field.identifier] = position
        @mapping_names[field.name] = position
      end
      self
    end

    def delete(name_or_identifier)
      position = @mapping_identifiers.delete(name_or_identifier) || @mapping_names.delete(name_or_identifier)
      raise ArgumentError unless position
      @fields.delete_at(position)
    end

    def [](name_or_identifier)
      position = @mapping_identifiers[name_or_identifier] || @mapping_names[name_or_identifier]
      return nil unless position
      @fields[position]
    end

    def each(&block)
      @fields.each(&block)
    end

    def -(other_list)
      fl = FieldsList.new
      self.each do |field|
        unless other_list[field.identifier]
          fl << field
        else
        end
      end
      fl
    end

    def +(other_list)
      fl = FieldsList.new
      self.each do |field|
        fl << field
      end
      other_list.each do |field|
        fl << field
      end
      fl
    end
  end

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
    @fields = FieldsList.new
    @msg_def = nil

    # process msg_type
    if @msg_def = schema.message(msg_type)
      @msg_type = @msg_def.attributes['msgtype']
    end
    self.add_field("MsgType", @msg_type || msg_type)

    @extra_fields = extra_fields
  end

  def reset
    @value = nil
  end

  def add_required_header_fields
    schema.required_header_fields.each do |el|
      next if ['BeginString', 'BodyLength', 'MsgType', 'SendingTime'].include?(el.attributes['name'])

      if session.properties.has_key?(el.attributes['name'])
        self.add_field(el.attributes['name'], session.properties[el.attributes['name']])
      else
        raise "Header field '#{el.attributes['name']}' required, but could not locate data."
      end
    end
  end

  def add_sending_time_filed
    # sending time
    #self.add_field('SendingTime', Time.new.utc.strftime('%Y%m%d-%H:%M:%S.%3N')) # ruby 1.9 only
    t = Time.new.utc # the following is ruby 1.8-compatible:
    tf = t.to_f
    milliseconds = ((tf - tf.floor) * 1000).round.to_s.ljust(3, '0')
    self.add_field('SendingTime', t.strftime("%Y%m%d-%H:%M:%S.#{milliseconds}"))
  end

  def add_extra_fields
    @extra_fields.each_pair do |key, value|
      self.add_field(key, value)
    end
  end

  def add_message_definition_fields
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
      add_extra_fields

      msg_to_string
    end
  end

  def add_field(name, value)
    @fields << Field.new(schema, name, value)

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
    msg_str = Field.new(schema, "BeginString", @begin_string).to_s << SEP  # msg_str = "8=FIX.4.4" << "|"
    msg_str << Field.new(schema, "BodyLength", msg_body_str.length).to_s   # msg_str << "9=79"
    msg_str << msg_body_str << SEP                                         # meg_str << "|35=A|49=SenderCompID|56=TargetCompID|34=1|52=20130321-10:56:24.765|98=0|108=30" << "|"
    msg_str << checksum_field(msg_str) << SEP                              # msg_str << "10=006" << "|"
    msg_str                                                                # "8=FIX.4.4|9=79|35=A|49=SenderCompID|56=TargetCompID|34=1|52=20130321-10:56:24.765|98=0|108=30|10=006|"
  end

  def header_fields
    schema.header_fields.inject(FieldsList.new) do |list, schema_filed|
      if field = @fields[schema_filed.attributes['name']]
        list << field
      end
      list
    end
  end

  def msg_body
    h_fields = header_fields
    body_fields = @fields - h_fields
    fields = h_fields + body_fields

    "".tap do |str|
      str << SEP + fields.map(&:to_s).join(SEP)
    end
  end

  def checksum_field(str)
    Field.new(schema, "CheckSum", self.class.checksum(str)).to_s
  end
end

