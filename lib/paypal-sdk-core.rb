require "paypal-sdk/core/version"
require "paypal-sdk/core/config"
require "paypal-sdk/core/logging"

module PayPal
  module SDK
    module Core

      autoload :Authentication, "paypal-sdk/core/authentication"

      module API
        autoload :Base,     "paypal-sdk/core/api/base"
        autoload :Merchant, "paypal-sdk/core/api/merchant"
        autoload :Platform, "paypal-sdk/core/api/platform"
        autoload :IPN,      "paypal-sdk/core/api/ipn"

        module DataTypes
          autoload :Base, "paypal-sdk/core/api/data_types/base"
          autoload :Enum, "paypal-sdk/core/api/data_types/enum"
          autoload :SimpleTypes,    "paypal-sdk/core/api/data_types/simple_types"
          autoload :ArrayWithBlock, "paypal-sdk/core/api/data_types/array_with_block"
        end
      end

      module Util
        autoload :OauthSignature, "paypal-sdk/core/util/oauth_signature"
        autoload :OrderedHash,    "paypal-sdk/core/util/ordered_hash"
      end

      module Credential
        autoload :Base,         "paypal-sdk/core/credential/base"
        autoload :Certificate,  "paypal-sdk/core/credential/certificate"
        autoload :Signature,    "paypal-sdk/core/credential/signature"

        module ThirdParty
          autoload :Token,    "paypal-sdk/core/credential/third_party/token"
          autoload :Subject,  "paypal-sdk/core/credential/third_party/subject"
        end
      end

    end
  end
end
