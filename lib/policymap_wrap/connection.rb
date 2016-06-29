module PolicyMap

  class Connection

    attr_accessor :debug
    attr_reader :client_id

    def initialize(client_id, username, password, proxy_url)
      @client_id = client_id
      @username = username
      @password = password
      @proxy_url = proxy_url
      @debug = false
    end

    def get(endpoint, data=nil)
      request :get, endpoint, data
    end

    HTTP_RESPONSES = { '100' => 'Continue', '101' => 'SwitchProtocol', '200' => 'OK', '201' => 'Created', '202' => 'Accepted', '203' => 'NonAuthoritativeInformation',
                         '204' => 'NoContent', '205' => 'ResetContent', '206' => 'PartialContent', '300' => 'MultipleChoice', '301' => 'MovedPermanently',
                         '302' => 'Found', '303' => 'SeeOther', '304' => 'NotModified', '305' => 'UseProxy', '307' => 'TemporaryRedirect', '400' => 'BadRequest',
                         '401' => 'Unauthorized', '402' => 'PaymentRequired', '403' => 'Forbidden', '404' => 'NotFound', '405' => 'MethodNotAllowed',
                         '406' => 'NotAcceptable', '407' => 'ProxyAuthenticationRequired', '408' => 'RequestTimeOut', '409' => 'Conflict', '410' => 'Gone',
                         '411' => 'LengthRequired', '412' => 'PreconditionFailed', '413' => 'RequestEntityTooLarge', '414' => 'RequestURITooLong',
                         '415' => 'UnsupportedMediaType', '416' => 'RequestedRangeNotSatisfiable', '417' => 'ExpectationFailed', '500' => 'InternalServerError',
                         '501' => 'NotImplemented', '502' => 'BadGateway', '503' => 'ServiceUnavailable', '504' => 'GatewayTimeOut', '505' => 'VersionNotSupported' }

    MAX_RETRIES = 10

  private

    def request(method, endpoint, data)
      headers = { 'User-Agent' => "PolicyMap Ruby Client v#{VERSION}" }

      if [:get].include?(method) && !data.nil?
        endpoint = endpoint + '?' + build_query(data)
      end

      if debug
        puts "request: #{method.to_s.upcase} #{endpoint}"
        puts "headers:"
        headers.each do |key, value|
          puts "#{key}=#{value}"
        end
      end

      response = send_request(method, endpoint, headers, data)

      if debug
        puts "\nresponse: #{response.code}"
        puts "headers:"
        response.headers.each do |key, value|
          puts "#{key}=#{value}"
        end
        puts "body:"
        puts response.body
      end

      raise_errors(response)

      if response.body.empty?
        content = nil
      else
        begin
          content = Yajl::Parser.new.parse(response.body)
        rescue Yajl::ParseError
          raise DecodeError, "content: <#{response.body}>"
        end
      end

      content
    end

    def build_query(data)
      data = data.to_a if data.is_a?(Hash)
      data.map do |key, value|
        [key.to_s, URI.escape(value.to_s)].join('=')
      end.join('&')
    end

    def send_request(method, endpoint, headers, data)
      n = MAX_RETRIES
      RestClient.proxy = @proxy_url unless @proxy_url.nil?
      begin
        response = RestClient::Request.execute(:method => method,
                                               :url => endpoint,
                                               :headers => headers,
                                               :user => @username,
                                               :password => @password)
      rescue => e
        n -= 1

        if n > 0
          puts "Retry number #{n}"
          retry
        else
          raise_errors(e.response)
        end
      end

      response
    end

    def raise_errors(response)
      response_description = "(#{response.code}): #{HTTP_RESPONSES[response.code.to_s]}"
      response_description += " - #{response.body}" unless response.body.empty?

      case response.code.to_i
        when 401
          raise Unauthorized
        when 404
          raise NotFound
        when 500
          raise ServerError, "PolicyMap had an internal error. Please let them know. #{response_description}"
        when 502..503
          raise Unavailable, response_description
        else
          unless response.code.to_i == 200
            raise PolicyMapError, response_description
          end
      end
    end

  end

end