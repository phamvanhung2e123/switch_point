# frozen_string_literal: true

require 'active_support/lazy_load_hooks'
require 'switch_point/config'
require 'switch_point/version'
require 'log_connection_name'
module SwitchPoint
  module ClassMethods
    def configure(&block)
      block.call(config)
    end

    def config
      @config ||= Config.new
    end

    def slave_all!
      config.each_key do |name|
        slave!(name)
      end
    end

    def slave!(name)
      ProxyRepository.checkout(name).slave!
    end

    def master_all!
      config.each_key do |name|
        master!(name)
      end
    end

    def master!(name)
      ProxyRepository.checkout(name).master!
    end

    def with_slave(*names, &block)
      with_mode(:slave, *names, &block)
    end

    def with_slave_all(&block)
      with_slave(*config.keys, &block)
    end

    def with_master(*names, &block)
      with_mode(:master, *names, &block)
    end

    def with_master_all(&block)
      with_master(*config.keys, &block)
    end

    def with_mode(mode, *names, &block)
      names.reverse.inject(block) do |func, name|
        lambda do
          ProxyRepository.checkout(name).with_mode(mode, &func)
        end
      end.call
    end
  end
  extend ClassMethods
end
ActiveSupport.on_load(:active_record) do
  require 'switch_point/model'
  ActiveRecord::Base.logger = Logger.new STDOUT
  ActiveRecord::Base.include(SwitchPoint::Model)
end
