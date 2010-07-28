module PolicyMap

  class Endpoint

    class << self

      def endpoint_url
        [REALM, 's/'].join('/')
      end
      
    end

  end

end
