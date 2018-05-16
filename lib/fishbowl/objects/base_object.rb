module Fishbowl::Objects
  class BaseObject
    def send_request(request, expected_response = 'FbiMsgsRs')
      get_connection
      code, response = @connection.send(build_request(request), expected_response)
      Fishbowl::Errors.confirm_success_or_raise(code)
      puts "Response successful" if Fishbowl.configuration.debug.eql? true
      close
      [code, response]
    end
    
    def set_connection(connection, retain_connection = false)
      @connection = connection
      @retain_connection = retain_connection
    end

    def get_connection
      @connection = Fishbowl::Connection.new if @connection.nil?
      @connection.get_connection
      @connection
    end
    
    def close
      @connection.close unless @retain_connection.eql? true
    end
  protected

    def self.attributes
      %w{ID}
    end

    def parse_attributes
      self.class.attributes.each do |field|
        field = field.to_s

        if field == 'ID'
          instance_var = 'db_id'
        elsif field.match(/^[A-Z]{3,}$/)
          instance_var = field.downcase
        else
          instance_var = field.gsub(/ID$/, 'Id').underscore
        end

        instance_var = '@' + instance_var
        value = @xml.xpath(field).first.nil? ? nil : @xml.xpath(field).first.inner_text
        instance_variable_set(instance_var, value)
      end
    end

  private

    def build_request(request)
      new_req = Nokogiri::XML::Builder.new do |xml|
        xml.FbiXml {
          if @connection.ticket.nil?
            xml.Ticket
          else
            xml.Ticket {
              xml.Key @connection.ticket
            }
          end

          xml.FbiMsgsRq {
            if request.respond_to?(:to_xml)
              xml << request.doc.xpath("request/*").to_xml
            else
              xml.send(request.to_s)
            end
          }
        }
      end
      Nokogiri::XML(new_req.to_xml).root
    end

  end
end
