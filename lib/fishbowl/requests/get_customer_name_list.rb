module Fishbowl::Requests
  def self.get_customer_name_list
    _, response = Fishbowl::Objects::BaseObject.new.send_request('CustomerNameListRq', 'CustomerNameListRs')

    results = []
    response.xpath(".//Customers/Name").each do |customer_xml|
      puts customer_xml if Fishbowl.configuration.debug.eql? true
      results << customer_xml.inner_text
    end
    puts 'Writing customers' if Fishbowl.configuration.debug.eql? true
    puts results if Fishbowl.configuration.debug.eql? true
    results
  end
end
