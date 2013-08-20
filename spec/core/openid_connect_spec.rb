require 'spec_helper'

describe PayPal::SDK::OpenIDConnect do
  OpenIDConnect = PayPal::SDK::OpenIDConnect

  before :all do
    OpenIDConnect.set_config( :client_id => "client_id", :openid_redirect_uri => "http://google.com" )
  end

  it "Validate user_agent" do
    OpenIDConnect::API.user_agent.should match "PayPalSDK/openid-connect-ruby"
  end

  describe "generate_authorize_url" do

    it "generate autorize_url" do
      url = OpenIDConnect::Tokeninfo.authorize_url
      url.should match "client_id=client_id"
      url.should match Regexp.escape("redirect_uri=#{CGI.escape("http://google.com")}")
      url.should match "scope=openid"
    end

    describe "sandbox" do
      before do
        PayPal::SDK.configure(:mode => "sandbox")
      end

      it "generates a sandbox authorize url" do
        url = OpenIDConnect::Tokeninfo.authorize_url
        url.should match "sandbox.paypal.com"
      end
    end
  end

  it "Override authorize_url params" do
    url = OpenIDConnect.authorize_url(
      :client_id => "new_client_id",
      :redirect_uri => "http://example.com",
      :scope => "openid profile")
    url.should match "client_id=new_client_id"
    url.should match Regexp.escape("redirect_uri=#{CGI.escape("http://example.com")}")
    url.should match Regexp.escape("scope=#{CGI.escape("openid profile")}")
  end

  it "Generate logout_url" do
    url = OpenIDConnect.logout_url
    url.should match "logout=true"
    url.should match Regexp.escape("redirect_uri=#{CGI.escape("http://google.com")}")
    url.should_not match "id_token"
  end

  it "Override logout_url params" do
    url = OpenIDConnect.logout_url({
      :redirect_uri => "http://example.com",
      :id_token  => "testing" })
    url.should match Regexp.escape("redirect_uri=#{CGI.escape("http://example.com")}")
    url.should match "id_token=testing"
  end

  describe "Validation" do
    it "Create token" do
      lambda{
        tokeninfo = OpenIDConnect::Tokeninfo.create("invalid-autorize-code")
      }.should raise_error PayPal::SDK::Core::Exceptions::BadRequest
    end

    it "Refresh token" do
      lambda{
        tokeninfo = OpenIDConnect::Tokeninfo.refresh("invalid-refresh-token")
      }.should raise_error PayPal::SDK::Core::Exceptions::BadRequest
    end

    it "Get userinfo" do
      lambda{
        userinfo = OpenIDConnect::Userinfo.get("invalid-access-token")
      }.should raise_error PayPal::SDK::Core::Exceptions::UnauthorizedAccess
    end
  end

  describe "Tokeninfo" do
    before do
      @tokeninfo = OpenIDConnect::Tokeninfo.new( :access_token => "test_access_token",
        :refresh_token => "test_refresh_token",
        :id_token => "test_id_token" )
    end

    it "create" do
      OpenIDConnect::Tokeninfo.api.stub( :post => { :access_token => "access_token" } )
      tokeninfo = OpenIDConnect::Tokeninfo.create("authorize_code")
      tokeninfo.should be_a OpenIDConnect::Tokeninfo
      tokeninfo.access_token.should eql "access_token"
    end

    it "refresh" do
      @tokeninfo.api.stub( :post => { :access_token => "new_access_token" } )
      @tokeninfo.access_token.should eql "test_access_token"
      @tokeninfo.refresh
      @tokeninfo.access_token.should eql "new_access_token"
    end

    it "userinfo" do
      @tokeninfo.api.stub( :post => { :name => "Testing" } )
      userinfo = @tokeninfo.userinfo
      userinfo.should be_a OpenIDConnect::Userinfo
      userinfo.name.should eql "Testing"
    end

    describe "logout_url" do
      it "Generate logout_url" do
        url = @tokeninfo.logout_url
        url.should match "id_token=test_id_token"
        url.should match "logout=true"
        url.should match Regexp.escape("redirect_uri=#{CGI.escape("http://google.com")}")
      end

      describe "sandbox" do
        before do
          PayPal::SDK.configure(:mode => "sandbox")
        end

        it "generates a sandbox logout url" do
          url = @tokeninfo.logout_url
          url.should match "sandbox.paypal.com"
        end
      end
    end
  end

  describe "Userinfo" do
    it "get" do
      OpenIDConnect::Userinfo.api.stub( :post => { :name => "Testing" } )

      userinfo = OpenIDConnect::Userinfo.get("access_token")
      userinfo.should be_a OpenIDConnect::Userinfo
      userinfo.name.should eql "Testing"

      userinfo = OpenIDConnect::Userinfo.get( :access_token => "access_token" )
      userinfo.should be_a OpenIDConnect::Userinfo
      userinfo.name.should eql "Testing"
    end
  end


end
