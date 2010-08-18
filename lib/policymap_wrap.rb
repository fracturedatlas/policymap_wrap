require 'uri'
require 'yajl'
require 'curb'

require 'policymap_wrap/connection'
require 'policymap_wrap/endpoint'
require 'policymap_wrap/hash_utils'
require 'policymap_wrap/client'

module PolicyMap
  REALM = "http://www.policymap.com"
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  
  class PolicyMapError < StandardError; end
  class InsufficientArgsForSearch < PolicyMapError; end
  class Unauthorized < PolicyMapError; end
  class NotFound < PolicyMapError; end
  class ServerError < PolicyMapError; end
  class Unavailable < PolicyMapError; end
  class DecodeError < PolicyMapError; end
  class NoConnectionEstablished < PolicyMapError; end
end
