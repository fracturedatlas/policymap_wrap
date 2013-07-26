module PolicyMap

  class Client

    BOUNDARY_TYPES = {
      :state                  => 2,
      :county                 => 4,
      :census_tract           => 6,
      :zip                    => 8,
      :block_group            => 15,
      :city                   => 16,
      :congressional_district => 23,
      :assembly_district      => 25,
      :senate_district        => 24
    }.freeze

    INDICATORS = {
      :average_vehicles_per_household                   => 9873779,
      :broadcasting                                     => 9584691,
      :distressed_community                             => 9629156,
      :percent_homeowners                               => 9873049,
      :total_population                                 => 9876593,
      :independent_artists                              => 9618303,
      :median_gross_rent                                => 9873661,
      :median_gross_rent_2009                           => 9873663,
      :median_home_value                                => 9873606,
      :median_household_income                          => 9871831,
      :movie_and_sound_industries                       => 9584731,
      :museums_and_historical_sites                     => 9584676,
      :other_info_services                              => 9584624,
      :percent_moved_in_since_1990                      => 9873776,
      :percent_who_commute_to_work_using_public_transit => 9873811,
      :percent_african_american                         => 9876222,
      :percent_native_american                          => 9876623,
      :percent_asian                                    => 9876202,
      :percent_foreign_born                             => 9869060,
      :percent_hispanic                                 => 9876280,
      :percent_pacific_islander                         => 9876468,
      :poverty_rate                                     => 9871807,
      :percent_disabled                                 => 9869050,
      :percent_65_or_older                              => 9869059,
      :percent_under_18                                 => 9869063,
      :percent_college_degree                           => 9873916,
      :percent_high_school_or_less                      => 9873913,
      :percent_mixed_race                               => 9876437,
      :percent_vacant_units                             => 9631221,
      :percent_white                                    => 9876415,
      :percent_graduate_degree                          => 9873904,
      :performing_arts_and_spectator_sports             => 9584608,
      :publishing_industries                            => 9584638,
      :unemployment_rate                                => 9841103,
      :vacancy_rate                                     => 9876608
    }.freeze

    @@connection = nil
    @@debug = false
    @@default_options = nil
    @@boundary_types_by_id = nil

    class << self

      def set_credentials(client_id, username, password, proxy_url=nil)
        @@default_options = { :id => client_id, :ty => 'data', :f => 'j', :af => '1' }
        @@connection = Connection.new(client_id, username, password, proxy_url)
        @@connection.debug = @@debug
        true
      end

      def debug=(debug_flag)
        @@debug = debug_flag
        @@connection.debug = @@debug if @@connection
      end

      def debug
        @@debug
      end

      def boundary_types
        BOUNDARY_TYPES
      end

      def indicators
        INDICATORS
      end

      def query_search(*args)
        default_options = @@default_options
        default_options[:t] = "sch"

        options = extract_options!(args)

        raise InsufficientArgsForSearch unless options.has_key?(:boundary_types) && options.has_key?(:query)

        options[:boundary_types] = sanitized_boundary_types(options[:boundary_types])
        HashUtils.rename_key!(options, :boundary_types, :bt)
        HashUtils.rename_key!(options, :query, :ss)
        HashUtils.rename_key!(options, :state, :sst) if options.has_key?(:state)
        HashUtils.rename_key!(options, :county, :sco) if options.has_key?(:county)
        HashUtils.rename_key!(options, :census_tract, :sct) if options.has_key?(:census_tract)

        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        result['sch']
      end

      def boundary_search(*args)
        default_options = @@default_options
        default_options[:t] = "bnd"

        options = extract_options!(args)

        raise InsufficientArgsForSearch unless options.has_key?(:boundary_types) || options.has_key?(:boundary_ids)

        options[:boundary_types] = sanitized_boundary_types(options[:boundary_types])
        options[:boundary_ids] = Array(options[:boundary_ids]).join(',') if options.has_key?(:boundary_ids)
        HashUtils.rename_key!(options, :boundary_types, :bt) if options.has_key?(:boundary_types)
        HashUtils.rename_key!(options, :boundary_ids, :bi) if options.has_key?(:boundary_ids)
        HashUtils.rename_key!(options, :lng, :lon) if options.has_key?(:lng)

        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        result["bnd"]
      end

      def indicator_search(*args)
        default_options = @@default_options
        default_options[:t] = "ind"

        options = extract_options!(args)

        raise InsufficientArgsForSearch unless options.has_key?(:indicators) && (options.has_key?(:boundary_types) || options.has_key?(:boundary_ids))

        options[:indicators] = sanitized_indicators(options[:indicators])
        options[:boundary_types] = sanitized_boundary_types(options[:boundary_types])
        options[:boundary_ids] = Array(options[:boundary_ids]).join(',') if options.has_key?(:boundary_ids)
        HashUtils.rename_key!(options, :indicators, :ii)
        HashUtils.rename_key!(options, :boundary_types, :bt) if options.has_key?(:boundary_types)
        HashUtils.rename_key!(options, :boundary_ids, :bi) if options.has_key?(:boundary_ids)
        HashUtils.rename_key!(options, :lng, :lon) if options.has_key?(:lng)

        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        result["ind"]
      end

      def containment_search(*args)
        default_options = @@default_options
        default_options[:t]  = 'bnd'

        options = extract_options!(args)

        raise InsufficientArgsForSearch unless options.has_key?(:boundary_types) && options.has_key?(:boundary_id)

        options[:boundary_types] = sanitized_boundary_types(options[:boundary_types])
        HashUtils.rename_key!(options, :boundary_types, :cbt)
        HashUtils.rename_key!(options, :boundary_id, :bi)


        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        result['bnd']
      end

      def get(endpoint, data=nil)
        raise NoConnectionEstablished  if @@connection.nil?
        @@connection.get endpoint, data
      end

    private

      def extract_options!(args)
        if args.last.is_a?(Hash)
          return args.pop
        else
          return {}
        end
      end

      def sanitized_boundary_types(types)
        # Convert :all to an array of all types
        types = Array(types)
        types = BOUNDARY_TYPES.keys if !types.empty? && :all == types.first.to_sym

        # Convert symbols to a list of numbers
        types.map { |bt| BOUNDARY_TYPES[bt] }.join(',')
      end

      def sanitized_indicators(indicators)
        # Convert :all to an array of all types
        indicators = Array(indicators)
        indicators = INDICATORS.keys if !indicators.empty? && :all == indicators.first.to_sym

        # Convert symbols to a list of numbers
        indicators.map { |i| INDICATORS[i] }.join(',')
      end

    end

  end

end
