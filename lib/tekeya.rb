require "tekeya/version"
require "active_support"
require "mebla/railtie" if defined?(Rails)

module Tekeya
  extend ActiveSupport::Autoload

  # Dependencies
  autoload :Redis, 'redis'
  autoload :Rebat, 'rebat'
  autoload :Mongoid
  autoload :ActiveRecord
  # Modules
  autoload :Configuration
  autoload :Entity
  autoload :Group

  # Configure Tekeya
  #
  # Example::
  # 
  #   Tekeya.configure do |config|
  #     redis_host = "localhost"
  #     redis_port = 9200
  #     flockdb_host = 9200
  #     flockdb_port = 9200
  #   end
  def self.configure(&block)
    yield Tekeya::Configuration.instance
  end

  def self.relations
    return Tekeya::Configuration.instance.rebat
  end
end
