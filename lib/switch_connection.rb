# frozen_string_literal: true

require 'active_support/lazy_load_hooks'
require 'switch_connection/config'
require 'switch_connection/version'
require 'log_connection_name'
module SwitchConnection
  module ClassMethods
    def configure(&block)
      block.call(config)
    end

    def config
      @config ||= Config.new
    end
  end
  extend ClassMethods
end
ActiveSupport.on_load(:active_record) do
  require 'switch_connection/model'
  ActiveRecord::Base.include(SwitchConnection::Model)
end
