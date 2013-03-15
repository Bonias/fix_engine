class FIX::Response
  attr_accessor :session
  attr_reader :response

  def schema
    session.schema
  end

  def initialize(session, response)
    @session = session
    @response = {}
    response.split("\01").each do |field|
      tag, val = field.split('=', 2)
      if node_field = schema.field(tag)
        tag_to_set = node_field.attributes['name']
        val_to_set = val
        #@response[node_field[0].attributes['name']] = val
      else
        tag_to_set = tag
        val_to_set = val
        #@response[tag] = val
      end
      if @response.has_key?(tag_to_set)
        if @response[tag_to_set].is_a?(Array)
          @response[tag_to_set] << val_to_set
        else
          first_member = @response[tag_to_set]
          @response[tag_to_set] = [first_member, val_to_set]
        end
      else
        @response[tag_to_set] = val_to_set
      end
    end
  end

  def pretty_print(header = true)
    puts '*** Message ***' if header
    p @response
    puts '*** End Message ***'
    puts
  end
end
