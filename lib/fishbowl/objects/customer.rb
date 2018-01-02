module Fishbowl::Objects
  class Customer < BaseObject
    attr_accessor :customer_id, :account_id, :status, :def_payment_terms, :def_ship_terms, :tax_rate, :name, :number, :date_created,
      :date_last_modified, :last_changed_user, :credit_limit, :tax_exempt_number, :note, :active_flag, :accounting_id, :default_salesman,
      :job_depth, :url

    def self.attributes
      %w{CustomerID AccountID Status DefPaymentTerms DefPaymentTerms DefShipTerms TaxRate Name Number DateCreated DateLastModified LastChangedUser CreditLimit TaxExemptNumber Note ActiveFlag AccountingID DefaultSalesman JobDepth URL}
    end

    def initialize(customer_xml)
      @xml = customer_xml
      parse_attributes
      self
    end
  end
end