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
      :assembly_district      => 49,
      :senate_district        => 48
    }.freeze

    INDICATORS = {
      :avg_vehicles_per_household                                    => 9873779,
      :broadcasting_except_internet                                  => 9584691,
      :distressed_community                                          => 9629156,
      :homeownership_rate                                            => 9873049,
      :housing_units                                                 => 9876598,
      :independent_artists                                           => 9618303,
      :median_gross_rent                                             => 9873661,
      :median_gross_rent                                             => 9873663,
      :median_home_value                                             => 9873606,
      :median_household_income                                       => 9871831,
      :motion_picture_and_sound_recording_industries                 => 9584731,
      :museums_historical_sites_and_similar                          => 9584676,
      :other_information_services                                    => 9584624,
      :pct_h_hs_moved_in_since1990                                   => 9873776,
      :pct_of_people_who_took_public_transit_to_work                 => 9873811,
      :percent_african_american_population                           => 9876222,
      :percent_american_indian_or_alaskan_native_population          => 9876623,
      :percent_asian_population                                      => 9876202,
      :percent_foreign_born_population                               => 9869060,
      :percent_hispanic_population                                   => 9876280,
      :percent_native_hawaiian_and_other_pacific_islander_population => 9876468,
      :percent_of_people_in_poverty                                  => 9871807,
      :percent_people_over5_with_disability                          => 9869050,
      :percent_population65                                          => 9869059,
      :percent_population_under18                                    => 9869063,
      :percent_population_with_at_least_bachelors_degree             => 9873916,
      :percent_population_with_hs_diploma                            => 9873913,
      :percent_two_or_more_races_population                          => 9876437,
      :percent_vacant_units                                          => 9631221,
      :percent_white_population                                      => 9876415,
      :percent_with_post_graduate_degree                             => 9873904,
      :performing_arts_spectator_sports_and_related                  => 9584608,
      :publishing_industries_except_internet                         => 9584638,
      :unemployment_rate                                             => 9841103,
      :vacancy_rate                                                  => 9876608
    }.freeze

    @@connection = nil
    @@debug = false
    @@default_options = nil

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
        HashUtils.rename_key!(options, :query, :s)
        HashUtils.rename_key!(options, :state, :st) if options.has_key?(:state)
        HashUtils.rename_key!(options, :county, :co) if options.has_key?(:county)
        HashUtils.rename_key!(options, :census_tract, :ct) if options.has_key?(:census_tract)

        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        result['sch'].collect {|hsh| HashUtils.symbolize_keys(hsh) }
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
        HashUtils.recursively_symbolize_keys(result["bnd"])
      end

      def indicator_search(*args)
        default_options = @@default_options
        default_options[:t] = "ind"

        options = extract_options!(args)

        raise InsufficientArgsForSearch unless options.has_key?(:indicators) && (options.has_key?(:boundary_types) || options.has_key?(:boundary_ids))

        options[:indicators] = Array(options[:indicators]).collect {|i| INDICATORS[i] }.join(',')
        options[:boundary_types] = sanitized_boundary_types(options[:boundary_types])
        options[:boundary_ids] = Array(options[:boundary_ids]).join(',') if options.has_key?(:boundary_ids)
        HashUtils.rename_key!(options, :indicators, :ii)
        HashUtils.rename_key!(options, :boundary_types, :bt) if options.has_key?(:boundary_types)
        HashUtils.rename_key!(options, :boundary_ids, :bi) if options.has_key?(:boundary_ids)
        HashUtils.rename_key!(options, :lng, :lon) if options.has_key?(:lng)

        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        HashUtils.recursively_symbolize_keys(result["ind"])
      end

      def containment_search(*args)
        default_options = @@default_options
        default_options[:t] = "cnt"

        options = extract_options!(args)

        raise InsufficientArgsForSearch unless options.has_key?(:boundary_types) && options.has_key?(:boundary_id)

        options[:boundary_types] = sanitized_boundary_types(options[:boundary_types])
        HashUtils.rename_key!(options, :boundary_types, :cbt)
        HashUtils.rename_key!(options, :boundary_id, :bi)


        options = default_options.merge(options)

        result = get(Endpoint.endpoint_url, options)
        result['cnt'].first
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
        types = BOUNDARY_TYPES.keys if types && :all == types.first.to_sym

        # Convert symbols to a list of numbers
        types.map { |bt| BOUNDARY_TYPES[bt] }.join(',')
      end

    end

  end

end
