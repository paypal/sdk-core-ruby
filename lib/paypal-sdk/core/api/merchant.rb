require 'xmlsimple'

module PayPal::SDK::Core

  module API

    # Use SOAP protocol to communicate with the Merchant Web services
    # == Example
    #   api       = API::Merchant.new
    #   response  = api.request("TransactionSearch", { "StartDate" => "2012-09-30T00:00:00+0530",
    #      "EndDate" => "2012-10-01T00:00:00+0530" })
    class Merchant < Base


      Namespaces = {
        "@xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
        "@xmlns:ns"      => "urn:ebay:api:PayPalAPI",
        "@xmlns:ebl"     => "urn:ebay:apis:eBLBaseComponents",
        "@xmlns:cc"      => "urn:ebay:apis:CoreComponentTypes",
        "@xmlns:ed"      => "urn:ebay:apis:EnhancedDataTypes"
      }
      ContentKey = API::DataTypes::Base::ContentKey.to_s
      DEFAULT_API_VERSION = "94.0"
      XML_OUT_OPTIONS   = { 'RootName' => nil, 'AttrPrefix' => true, 'ContentKey' => ContentKey,
        'noindent' => true, 'SuppressEmpty' => true }
      XML_IN_OPTIONS    = { 'AttrPrefix' => true, 'ForceArray' => false, 'ContentKey' => ContentKey }
      DEFAULT_PARAMS    = Util::OrderedHash.new.merge!({ "ebl:Version" => DEFAULT_API_VERSION })
      SKIP_ATTRIBUTES   = [ "@xmlns", "@xsi:type" ]
      SOAP_HTTP_AUTH_HEADER  = {
        :authorization  => "X-PP-AUTHORIZATION"
      }
      SOAP_AUTH_HEADER  = {
        :username   => "ebl:Username",
        :password   => "ebl:Password",
        :signature  => "ebl:Signature",
        :subject    => "ebl:Subject"
      }

      # Get SOAP or default end point
      def service_endpoint
        config.merchant_end_point || super || default_end_point(:merchant)
      end

      # Format the HTTP request content
      # === Arguments
      # * <tt>action</tt> -- Request action
      # * <tt>params</tt> -- Parameters for Action in Hash format
      # === Return
      # * <tt>request_path</tt> -- Soap request path. DEFAULT("/")
      # * <tt>request_content</tt> -- Request content in SOAP format.
      def format_request(action, params)
        credential_properties  = credential(uri.to_s).properties
        user_auth_header = map_header_value(SOAP_AUTH_HEADER, credential_properties)
        content_key      = params.keys.first.is_a?(Symbol) ? ContentKey.to_sym : ContentKey.to_s
        xml_out_options  = XML_OUT_OPTIONS.merge( 'ContentKey' => content_key )
        request_content = XmlSimple.xml_out({
          "soapenv:Envelope" => {
          content_key => (
              XmlSimple.xml_out({"soapenv:Header"  => { "ns:RequesterCredentials" => {
                  "ebl:Credentials" => user_auth_header
               }}}, xml_out_options) +
              XmlSimple.xml_out({"soapenv:Body"    => body(action, params)}, xml_out_options))
          }.merge(Namespaces)
        }, xml_out_options.merge('noescape' => true))
        header = map_header_value(SOAP_HTTP_AUTH_HEADER, credential_properties)
        [ @uri, request_content, header ]
      end

      # Format Response object
      # === Arguments
      # * <tt>action</tt> -- Request action
      # * <tt>response</tt> -- Response object
      # === Return
      # Parse the SOAP response content and return Hash object
      def format_response(action, response)
        if response.code == "200"
          hash = XmlSimple.xml_in(response.body, XML_IN_OPTIONS)
          hash = skip_attributes(hash)
          hash["Body"].find{|key_val| key_val[0] =~ /^[^@]/ }[1] || {}
        else
          format_error(response, response.message)
        end
      end

      private

      # Generate soap body
      # == Arguments
      # * <tt>action</tt> -- Request Action name
      # * <tt>params</tt> -- Parameters for the action.
      def body(action, params = {})
        { "ns:#{action}Req" => { "ns:#{action}Request" => DEFAULT_PARAMS.merge(params) } }
      end

      # Remove specified attributes from the given Hash
      # === Arguments
      # * <tt>hash</tt>   -- Hash object
      # * <tt>attrs</tt>  -- (Optional) Attribute list
      # * <tt>content_key</tt> -- (Optional) content key
      def skip_attributes(hash, attrs = SKIP_ATTRIBUTES, content_key = ContentKey)
        hash.each do |key, value|
          if attrs.include? key
            hash.delete(key)
          elsif value.is_a? Hash
            hash[key] = skip_attributes(value, attrs, content_key)
          elsif value.is_a? Array and value[0].is_a? Hash
            value.each_with_index do |array_value, index|
              value[index] = skip_attributes(array_value, attrs, content_key)
            end
          end
        end
        ( hash.one? and hash[content_key] ) ? hash[content_key] : ( hash.empty? ? nil : hash )
      end

      # Format Error object.
      # == Arguments
      # * <tt>exception</tt> -- Exception object or HTTP response object.
      # * <tt>message</tt> -- Readable error message.
      def format_error(exception, message)
        { "Ack" => "Failure", "Errors" => { "ShortMessage" => message, "LongMessage" => exception.to_s } }
      end
    end
  end
end
