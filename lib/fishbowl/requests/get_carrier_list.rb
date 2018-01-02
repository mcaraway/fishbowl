module Fishbowl::Requests
  def self.get_carrier_list
    _, response = Fishbowl::Objects::BaseObject.new.send_request('CarrierListRq', 'FbiMsgsRs/CarrierListRs')

    results = []

    response.xpath("//Carriers/Name").each do |carrier_xml|
      results << Fishbowl::Objects::Carrier.new(carrier_xml)
    end

    results
  end
end
