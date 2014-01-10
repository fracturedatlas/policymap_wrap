  module PolicyMap

  class Client

    BOUNDARY_TYPES = {
      :state                  => 2,
      :county                 => 4,
      :census_tract           => 6,
      :zip                    => 8,
      :block_group            => 15,
      :city                   => 16
    }.freeze

    INDICATORS = {
      :total_population                                 => 9869069,
      :percent_white                                    => 9869107,
      :percent_african                                  => 9868876,
      :percent_asian                                    => 9868853,
      :percent_pasific                                  => 9868902,
      :percent_hispanic                                 => 9868944,
      :percent_native                                   => 9869102,
      :percent_mixed_race                               => 9868873,
      :percent_male                                     => 9868906,
      :percent_female                                   => 9868899,
      :ages_18_20                                       => 9868855,
      :ages_21_24                                       => 9869071,
      :ages_25_34                                       => 9868907,
      :ages_35_44                                       => 9869023,
      :ages_45_54                                       => 9868972,
      :ages_55_64                                       => 9869076,
      :ages_65_or_older                                 => 9868923,
      :percent_high_school_or_less                      => 9873913,
      :percent_college_degree                           => 9873916,
      :percent_graduate_degree                          => 9873904,
      :median_household_income                          => 9871831,
      :unemployment_rate                                => 9841103,
      :percent_income_10000_14999                       => 9871925,
      :percent_income_15000_19999                       => 9871891,
      :percent_income_15000_24999                       => 9871888,
      :percent_income_20000_24999                       => 9871882,      
      :percent_income_25000_34999                       => 9871909,
      :percent_income_35000_49999                       => 9871840,
      :percent_income_50000_74999                       => 9871836,
      :percent_income_75000_99999                       => 9871932,
      :percent_income_100000_124999                     => 9871846,
      :percent_income_125000_149999                     => 9871989,
      :percent_income_150000_199999                     => 9871919,
      :percent_income_150000_or_more                    => 9871880,
      :percent_income_less_than_10000                   => 9871812,
      :percent_income_less_than_15000                   => 9871809,
      :percent_income_less_than_25000                   => 9871822,
      :percent_income_less_than_50000                   => 9871946,
      :percent_income_less_than_75000                   => 9871970,
      :percent_income_less_than_100000                  => 9871974,
      :percent_income_less_than_150000                  => 9871832
    }.freeze

    BASE_INDICATORS = {
      :total_population                                 => 9869069,
      :percent_white                                    => 9869107,
      :percent_african                                  => 9868876,
      :percent_asian                                    => 9868853,
      :percent_pasific                                  => 9868902,
      :percent_hispanic                                 => 9868944,
      :percent_native                                   => 9869102,
      :percent_mixed_race                               => 9868873,
      :percent_male                                     => 9868906,
      :percent_female                                   => 9868899,
      :ages_18_20                                       => 9868855,
      :ages_21_24                                       => 9869071,
      :ages_25_34                                       => 9868907,
      :ages_35_44                                       => 9869023,
      :ages_45_54                                       => 9868972,
      :ages_55_64                                       => 9869076,
      :ages_65_or_older                                 => 9868923,
      :percent_high_school_or_less                      => 9873913,
      :percent_college_degree                           => 9873916,
      :percent_graduate_degree                          => 9873904,
      :median_household_income                          => 9871831,
      :unemployment_rate                                => 9841103,
    }

    INCOME_INDICATORS = {
      :percent_income_10000_14999                       => 9871925,
      :percent_income_15000_19999                       => 9871891,
      :percent_income_15000_24999                       => 9871888,
      :percent_income_20000_24999                       => 9871882,      
      :percent_income_25000_34999                       => 9871909,
      :percent_income_35000_49999                       => 9871840,
      :percent_income_50000_74999                       => 9871836,
      :percent_income_75000_99999                       => 9871932,
      :percent_income_100000_124999                     => 9871846,
      :percent_income_125000_149999                     => 9871989,
      :percent_income_150000_199999                     => 9871919,
      :percent_income_150000_or_more                    => 9871880,
      :percent_income_less_than_10000                   => 9871812,
      :percent_income_less_than_15000                   => 9871809,
      :percent_income_less_than_25000                   => 9871822,
      :percent_income_less_than_50000                   => 9871946,
      :percent_income_less_than_75000                   => 9871970,
      :percent_income_less_than_100000                  => 9871974,
      :percent_income_less_than_150000                  => 9871832
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

      def base_indicators
        BASE_INDICATORS
      end

      def income_indicators
        INCOME_INDICATORS
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
