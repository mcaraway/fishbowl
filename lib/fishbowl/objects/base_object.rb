module Fishbowl::Objects
  class BaseObject
    def send_request(request, expected_response = 'FbiMsgsRs')
      code, response = Fishbowl::Connection.instance.send(build_request(request), expected_response)
      Fishbowl::Errors.confirm_success_or_raise(code)
      puts "Response successful" if Fishbowl.configuration.debug.eql? true
      [code, response]
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
          if Fishbowl::Connection.instance.ticket.nil?
            xml.Ticket
          else
            xml.Ticket {
              xml.Key Fishbowl::Connection.instance.ticket
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
