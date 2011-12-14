module PolicyMap

  class Client

    BOUNDARY_TYPES = { :state => 2, :county => 4, :city => 16, :zip => 8, :census_tract => 6,
                       :block_group => 15, :congressional_district => 23, :assembly_district => 48,
                       :senate_district => 49, :all => 'all' }

    INDICATORS = { :total_population => 9876598, :percent_african_american => 9876222, :percent_asian => 9876202,
                   :percent_pacific_islander => 9876468, :percent_hispanic => 9876280, :percent_native_american => 9876623,
                   :percent_mixed_race => 9876437, :percent_under_18 => 9869063, :percent_65_or_older => 9869059,
                   :percent_foreign_born => 9869060, :percent_disabled => 9869050, :percent_high_school_or_less => 9873913,
                   :percent_college_degree => 9873916, :percent_graduate_degree => 9873904, :median_home_value => 9873606,
                   :median_rent => 9873661, :percent_moved_in_since_1990 => 9873776, :percent_homeowners => 9873049,
                   :vacancy_rate => 9876608, :median_household_income => 9871831, :poverty_rate => 9871807,
                   :percent_white => 9876415, :percent_households_wo_car => 0, :average_vehicles_per_household => 9873779,
                   :percent_who_commute_to_work_using_public_transit => 9873811, :unemployment_rate => 9841103,
                   :independent_artists => 9618303, :performing_arts_and_spectator_sports => 9584608,
                   :movie_and_sound_industries => 9584731, :mueseums_and_historical_sites => 9584676,
                   :publishing_industries => 9584638, :broadcasting => 9584691, :other_info_services => 9584624, :all => 'all' }

    @@connection = nil
    @@debug = false
    @@default_options = nil

    class << self

      def set_credentials(client_id, username, password)
        @@default_options = { :id => client_id, :ty => 'data', :f => 'j', :af => '1' }
        @@connection = Connection.new(client_id, username, password)
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

        options[:boundary_types] = Array(options[:boundary_types]).collect {|bt| BOUNDARY_TYPES[bt] }.join(',')
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

        options[:boundary_types] = Array(options[:boundary_types]).collect {|bt| BOUNDARY_TYPES[bt] }.join(',') if options.has_key?(:boundary_types)
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
        options[:boundary_types] = Array(options[:boundary_types]).collect {|bt| BOUNDARY_TYPES[bt] }.join(',') if options.has_key?(:boundary_types)
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

        options[:boundary_types] = Array(options[:boundary_types]).collect {|bt| BOUNDARY_TYPES[bt] }.join(',')
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

    end

  end

end
