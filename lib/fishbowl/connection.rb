require 'nokogiri'

module Fishbowl
  class Connection
    include Singleton
    
    def initialize 
      puts "I'm being initialized!"
      raise Fishbowl::Errors::MissingHost if Fishbowl.configuration.host.nil?

      @host = Fishbowl.configuration.host
      @port = Fishbowl.configuration.port.nil? ? 28192 : Fishbowl.configuration.port

      @connection = TCPSocket.new @host, @port
      raise Fishbowl::Errors::ConnectionNotEstablished if @connection.nil?
      raise Fishbowl::Errors::MissingUsername if Fishbowl.configuration.host.nil?
      raise Fishbowl::Errors::MissingPassword if Fishbowl.configuration.host.nil?

      @username = Fishbowl.configuration.username
      @password = Fishbowl.configuration.password

      # code, response = Fishbowl::Objects::BaseObject.new.send_request(login_request)
      code, response = send(build_request(login_request), 'FbiMsgsRs')
      Fishbowl::Errors.confirm_success_or_raise(code)
      puts "Response successful" if Fishbowl.configuration.debug.eql? true

      @ticket = response.xpath("/FbiXml/Ticket/Key").text
      raise "Login failed" unless code.eql? "1000"
    end

    def host
      @host
    end

    def port
      @port
    end

    def username
      @username
    end

    def password
      @password
    end
    
    def ticket
      @ticket
    end

    def send(request, expected_response = 'FbiMsgsRs')
      puts 'opening connection...' if Fishbowl.configuration.debug.eql? true
      puts request if Fishbowl.configuration.debug.eql? true
      puts 'waiting for response...' if Fishbowl.configuration.debug.eql? true
      write(request)
      get_response(expected_response)
    end

    def close
      @connection.close
      @connection = nil
    end

      
    def get_connection()
      if @connection.nil?
        connect
        login
      end
      
      self.instance
    end

    private

    def connect()
      raise Fishbowl::Errors::MissingHost if Fishbowl.configuration.host.nil?

      @host = Fishbowl.configuration.host
      @port = Fishbowl.configuration.port.nil? ? 28192 : Fishbowl.configuration.port

      @connection = TCPSocket.new @host, @port

      self.instance
    end

    def login()
      raise Fishbowl::Errors::ConnectionNotEstablished if @connection.nil?
      raise Fishbowl::Errors::MissingUsername if Fishbowl.configuration.host.nil?
      raise Fishbowl::Errors::MissingPassword if Fishbowl.configuration.host.nil?

      @username = Fishbowl.configuration.username
      @password = Fishbowl.configuration.password

      code, response = Fishbowl::Objects::BaseObject.new.send_request(login_request)
      Fishbowl::Errors.confirm_success_or_raise(code)

      @ticket = response.xpath("/FbiXml/Ticket/Key").text
      raise "Login failed" unless code.eql? "1000"

      self.instance
    end
    
    def login_request
      Nokogiri::XML::Builder.new do |xml|
        xml.request {
          xml.LoginRq {
            xml.IAID          Fishbowl.configuration.app_id
            xml.IAName        Fishbowl.configuration.app_name
            xml.IADescription Fishbowl.configuration.app_description
            xml.UserName      Fishbowl.configuration.username
            xml.UserPassword  encoded_password
          }
        }
      end
    end

    def encoded_password
      Digest::MD5.base64digest(@password)
    end

    def write(request)
      body = request.to_xml
      size = [body.size].pack("L>")
      @connection.write(size)
      @connection.write(body)
    end

    def get_response(expectation)
      puts "reading response" if Fishbowl.configuration.debug.eql? true
      length = @connection.read(4).unpack('L>').join('').to_i
      response = Nokogiri::XML.parse(@connection.read(length))
      puts response if Fishbowl.configuration.debug.eql? true
      status_code = response.xpath("/FbiXml/FbiMsgsRs").attr("statusCode").value
      [status_code, response]
    end

    def build_request(request)
      new_req = Nokogiri::XML::Builder.new do |xml|
        xml.FbiXml {
          if @ticket.nil?
            xml.Ticket
          else
            xml.Ticket {
              xml.Key @ticket
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