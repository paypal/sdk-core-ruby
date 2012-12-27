require 'net/http'

module PayPal::SDK::Core

  module API
    # API class provide default functionality for accessing the API web services.
    # == Example
    #   api      = API::Base.new("AdaptivePayments")
    #   response = api.request("GetPaymentOptions", "")
    class Base

      include Configuration
      include Logging
      include Authentication

      attr_accessor :http, :uri, :service_name

      DEFAULT_END_POINTS = {
        :sandbox => {
          :platform => { # NVP EndPoint
            :three_token  => "https://svcs.sandbox.paypal.com/",
            :certificate  => "https://svcs.sandbox.paypal.com/"
          },
          :merchant => { # SOAP EndPoint
            :three_token  => "https://api-3t.sandbox.paypal.com/2.0",
            :certificate  => "https://api.sandbox.paypal.com/2.0"
          }
        },
        :live => {
          :platform => { # NVP EndPoint
            :three_token  => "https://svcs.paypal.com/",
            :certificate  => "https://svcs.paypal.com/"
          },
          :merchant => { # SOAP EndPoint
            :three_token  => "https://api-3t.paypal.com/2.0",
            :certificate  => "https://api.paypal.com/2.0"
          }
        }
      }
      DEFAULT_HTTP_HEADER = {}

      # Initialize API object
      # === Argument
      # * <tt>service_name</tt> -- (Optional) Service name
      # * <tt>environment</tt>  -- (Optional) Configuration environment to load
      # * <tt>options</tt> -- (Optional) Override configuration.
      # === Example
      #  new("AdaptivePayments")
      #  new("AdaptivePayments", :development)
      #  new(:wsdl_service)       # It load wsdl_service configuration
      def initialize(service_name = "", environment = nil, options = {})
        unless service_name.is_a? String
          environment, options, service_name = service_name, environment || {}, ""
        end
        @service_name = service_name
        set_config(environment, options)
      end

      # Override set_config method to create http connection on changing the configuration.
      def set_config(*args)
        super
        create_http_connection
      end

      # Create HTTP connection based on given service name or configured end point
      def create_http_connection
        service_path = "#{service_endpoint}/#{service_name}"
        @uri  = URI.parse(service_path)
        if config.http_proxy
          proxy = URI.parse(config.http_proxy)
          @http = Net::HTTP.new(@uri.host, @uri.port, proxy.host, proxy.port, proxy.user, proxy.password)
        else
          @http = Net::HTTP.new(@uri.host, @uri.port)
        end
        @uri.path = @uri.path.gsub(/\/+/, "/")
        configure_http_connection
      end

      # Configure HTTP connection based on configuration.
      def configure_http_connection
        http.use_ssl  = true
        http.ca_file  = config.ca_file if config.ca_file
        if config.http_timeout
          http.open_timeout = config.http_timeout
          http.read_timeout = config.http_timeout
        end
        add_certificate(http)
      end

      # Get configured API mode( sandbox or live)
      def api_mode
        api_modes   = DEFAULT_END_POINTS.keys
        config_mode = ( config.mode || api_modes.first ).to_sym
        api_modes.include?(config_mode) ? config_mode : api_modes.first
      end

      # Get default endpoint for the given service name
      # === Argument
      # * <tt>name</tt> -- Service name ( platform or merchant)
      # === Returns
      # Return service end point based on the configured API mode.
      def default_end_point(name)
        default_end_point = DEFAULT_END_POINTS[api_mode][name]
        if default_end_point
          config.cert_path ? default_end_point[:certificate] : default_end_point[:three_token]
        end
      end

      # Get service end point
      def service_endpoint
        config.end_point ? default_end_point(config.end_point.to_sym) : config.end_point
      end

      # Default Http header
      def default_http_header
        DEFAULT_HTTP_HEADER
      end

      # Generate HTTP request for given action and parameters
      # === Arguments
      # * <tt>action</tt> -- Action to perform
      # * <tt>params</tt> -- (Optional) Parameters for the action
      # * <tt>initheader</tt> -- (Optional) HTTP header
      def request(action, params = {}, initheader = {})
        start_time    = Time.now
        uri, content, header = format_request(action, params)
        initheader    = default_http_header.merge(header).merge(initheader)
        initheader.delete_if{|key, val| val.nil? }
        response      = @http.post(uri.path, content, initheader)
        format_response(action, response)
      rescue Net::HTTPBadGateway, Errno::ECONNRESET, Errno::ECONNABORTED, SocketError => error
        format_error(error, error.message)
      ensure
        log_event("Request: #{action}", start_time)
      end

      # Format Request data. It will be override by child class
      # == Arguments
      # * <tt>action</tt> -- Request action
      # * <tt>params</tt> -- Request parameters
      # == Return
      # * <tt>path</tt>   -- Formated request uri object
      # * <tt>params</tt> -- Formated request Parameters
      # * <tt>header</tt> -- HTTP Header
      def format_request(action, params)
        [ @uri, params, {} ]
      end

      # Format Response object. It will be override by child class
      # == Argument
      # * <tt>action</tt> -- Request action
      # * <tt>response</tt> -- HTTP response object
      def format_response(action, response)
        response
      end

      # Format Error object. It will be override by child class.
      # == Arguments
      # * <tt>exception</tt> -- Exception object.
      # * <tt>message</tt> -- Readable error message.
      def format_error(exception, message)
        raise exception
      end
    end
  end
end
