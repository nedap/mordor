module Mordor
  class Config
    class << self

      # Yields the configuration.
      #
      # ==== Block parameters
      # c<Hash>:: The configuration parameters.
      #
      # ==== Examples
      #   Merb::Config.use do |config|
      #     config[:exception_details] = false
      #     config[:log_stream]        = STDOUT
      #   end
      #
      # ==== Returns
      # nil
      #
      # :api: publicdef use
      def use
        @configuration ||= {}
        yield @configuration
        nil
      end

      # Retrieve the value of a config entry.
      #
      # ==== Parameters
      # key<Object>:: The key to retrieve the parameter for.
      #
      # ==== Returns
      # Object:: The value of the configuration parameter.
      #
      # :api: public
      def [](key)
        (@configuration ||= setup)[key]
      end

      # Set the value of a config entry.
      #
      # ==== Parameters
      # key<Object>:: The key to set the parameter for.
      # val<Object>:: The value of the parameter.
      #
      # :api: public
      def []=(key, val)
        (@configuration ||= setup)[key] = val
      end

      private

      # Returns the hash of default config values for Merb.
      #
      # ==== Returns
      # Hash:: The defaults for the config.
      #
      # :api: private
      def defaults
        @defaults ||= {
          :hostname => 'localhost',
          :port     => 27017,
          :database => 'development'
        }
      end

      # Sets up the configuration by storing the given settings.
      #
      # ==== Parameters
      # settings<Hash>::
      #   Configuration settings to use. These are merged with the defaults.
      #
      # ==== Returns
      # The configuration as a hash.
      #
      # :api: private
      def setup(settings = {})
        @configuration = defaults.merge(settings)
      end
    end

  end
end
