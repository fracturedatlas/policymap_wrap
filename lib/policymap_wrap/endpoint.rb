module PolicyMap

  class Endpoint

    class << self

      def endpoint_url
        [REALM, 'd/'].join('/')
      end

    end

  end

end
