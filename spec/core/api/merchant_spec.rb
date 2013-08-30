require 'spec_helper'

describe PayPal::SDK::Core::API::Merchant do

  Merchant = PayPal::SDK::Core::API::Merchant

  TransactionSearchParams = { "StartDate" => "2012-09-30T00:00:00+0530", "EndDate" => "2012-09-30T00:01:00+0530"}
  MassPayParams = { "ReceiverType" => "EmailAddress", "MassPayItem" => [{
            "ReceiverEmail" => "enduser_biz@gmail.com", "Amount" => { "@currencyID" => "USD", "value" => "3.00" } }] }

  it "Validate user_agent" do
    Merchant.user_agent.should match "PayPalSDK/sdk-core-ruby"
  end

  describe "Configuration" do
    it "service endpoint for sandbox" do
      client = Merchant.new
      client.service_endpoint.should eql "https://api-3t.sandbox.paypal.com/2.0/"
      client = Merchant.new( :mode => "sandbox" )
      client.service_endpoint.should eql "https://api-3t.sandbox.paypal.com/2.0/"
      client = Merchant.new( :mode => :sandbox )
      client.service_endpoint.should eql "https://api-3t.sandbox.paypal.com/2.0/"
      client = Merchant.new( :mode => "invalid" )
      client.service_endpoint.should eql "https://api-3t.sandbox.paypal.com/2.0/"
      client = Merchant.new( :mode => nil )
      client.service_endpoint.should eql "https://api-3t.sandbox.paypal.com/2.0/"

      client = Merchant.new(:with_certificate)
      client.service_endpoint.should eql "https://api.sandbox.paypal.com/2.0/"
    end

    it "service_endpoint for live" do
      client = Merchant.new( :mode => "live" )
      client.service_endpoint.should eql "https://api-3t.paypal.com/2.0/"
      client = Merchant.new( :mode => :live )
      client.service_endpoint.should eql "https://api-3t.paypal.com/2.0/"

      client = Merchant.new( :with_certificate, :mode => "live" )
      client.service_endpoint.should eql "https://api.paypal.com/2.0/"
    end

    it "override service endpoint" do
      client = Merchant.new( :merchant_endpoint => "http://example.com" )
      client.service_endpoint.should eql "http://example.com"
      client = Merchant.new( :merchant_endpoint => "http://example.com", :mode => :live )
      client.service_endpoint.should eql "http://example.com"
      client = Merchant.new( :endpoint => "http://example.com" )
      client.service_endpoint.should eql "http://example.com"
    end
  end

  describe "Success request" do
    it "with default configuration" do
      client    = Merchant.new
      response  = client.request("TransactionSearch", TransactionSearchParams )
      response["Ack"].should eql "Success"
      response  = client.request("MassPay", MassPayParams)
      response["Ack"].should eql "Success"
    end

    it "with ssl certificate" do
      client   = Merchant.new(:with_certificate)
      response  = client.request("TransactionSearch", TransactionSearchParams)
      response["Ack"].should eql "Success"
    end

    it "with oauth token" do
      client   = Merchant.new(:with_oauth_token)
      response  = client.request("TransactionSearch", TransactionSearchParams)
      response["Ack"].should eql "Success"
    end

    it "with raw request" do
      client   = Merchant.new
      response = client.request({
        "ns:TransactionSearchReq" => {
          "ns:TransactionSearchRequest" =>  TransactionSearchParams.merge("ebl:Version" => "94")
      } } )
      response["Ack"].should eql "Success"
    end
  end

  describe "Format request" do

    before :all do
      @client    = Merchant.new
    end

    it "should handle :value member" do
      payload = @client.format_request(:action => "Action", :params => { :amount => { :value => "50" } } )
      payload[:body].should match '<amount>50</amount>'
      payload = @client.format_request(:action => "Action", :params => { "amount" => { "value" => "50" } } )
      payload[:body].should match '<amount>50</amount>'
    end

    it "should handle attribute" do
      payload = @client.format_request(:action => "Action", :params => { :amount => { "@currencyID" => "USD", :value => "50" } } )
      payload[:body].should match '<amount currencyID="USD">50</amount>'
      payload = @client.format_request(:amount => "Action", :params => { "amount" => { "@currencyID" => "USD", "value" => "50" } } )
      payload[:body].should match '<amount currencyID="USD">50</amount>'
    end

    it "should handle members" do
      payload = @client.format_request(:action => "Action", :params => { :list => { :amount => { "@currencyID" => "USD", :value => "50" } } })
      payload[:body].should match '<list><amount currencyID="USD">50</amount></list>'
    end

    it "should handle array of members" do
      payload = @client.format_request(:action => "Action", :params => {
        :list => { :amount => [ { "@currencyID" => "USD", :value => "50" }, { "@currencyID" => "USD", :value => "25" } ] } })
      payload[:body].should match '<list><amount currencyID="USD">50</amount><amount currencyID="USD">25</amount></list>'
    end

    it "should handle namespace" do
      payload = @client.format_request(:action => "Action", :params => { :"ebl:amount" => { "@cc:currencyID" => "USD", :value => "50" } } )
      payload[:body].should match '<ebl:amount cc:currencyID="USD">50</ebl:amount>'
    end
  end

  describe "Failure request" do

    def should_be_failure(response, message = nil)
      response.should_not be_nil
      response["Ack"].should eql "Failure"
      response["Errors"].should_not be_nil
      errors = response["Errors"].is_a?(Array) ? response["Errors"][0] : response["Errors"]
      errors["ShortMessage"].should match message if message
    end

    it "invalid 3 token authentication" do
      client   = Merchant.new(:username => "invalid", :password => 1234 )
      response = client.request("TransactionSearch", TransactionSearchParams )
      should_be_failure(response, "Security error")
    end

    it "invalid ssl certificate authentication" do
      client   = Merchant.new(:with_certificate, :username => "invalid")
      response = client.request("TransactionSearch", TransactionSearchParams )
      should_be_failure(response, "Authorization Failed")
    end

    it "invalid action" do
      lambda {
        client   = Merchant.new
        response = client.request("InvalidAction", TransactionSearchParams )
      }.should raise_error PayPal::SDK::Core::Exceptions::ServerError
    end

    it "invalid params" do
      client   = Merchant.new
      response = client.request("TransactionSearch", { :invalid_params => "something" } )
      should_be_failure(response, "invalid argument")
    end

  end

end
