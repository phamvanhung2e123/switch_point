# frozen_string_literal: true

require 'switch_connection/error'
require 'switch_connection/proxy_repository'

module SwitchConnection
  module Model
    def self.included(model)
      super
      model.singleton_class.class_eval do
        include ClassMethods
        prepend MonkeyPatch
      end
    end

    def with_slave(&block)
      self.class.with_slave(&block)
    end

    def with_master(&block)
      self.class.with_master(&block)
    end

    def with_switch_point(new_switch_point_name, &block)
      self.class.with_switch_point(new_switch_point_name, &block)
    end

    def transaction_with(*models, &block)
      self.class.transaction_with(*models, &block)
    end

    module ClassMethods
      def with_slave(&block)
        if switch_point_proxy
          switch_point_proxy.with_slave(&block)
        else
          raise UnconfiguredError.new("#{name} isn't configured to use switch_point")
        end
      end

      def with_auto_slave(&block)
        if switch_point_proxy
          switch_point_proxy.with_auto_slave(&block)
        else
          raise UnconfiguredError.new("#{name} isn't configured to use switch_point")
        end
      end

      def with_master(&block)
        if switch_point_proxy
          switch_point_proxy.with_master(&block)
        else
          raise UnconfiguredError.new("#{name} isn't configured to use switch_point")
        end
      end

      def use_switch_point(name)
        assert_existing_switch_point!(name)
        @global_switch_point_name = name
      end

      def with_switch_point(new_switch_point_name)
        saved_switch_point_name = thread_local_switch_point_name
        self.thread_local_switch_point_name = new_switch_point_name
        yield
      ensure
        self.thread_local_switch_point_name = saved_switch_point_name
      end

      def switch_point_name
        thread_local_switch_point_name || @global_switch_point_name
      end

      def thread_local_switch_point_name
        Thread.current[:"thread_local_#{name}_switch_point_name"]
      end

      def thread_local_switch_point_name=(name)
        Thread.current[:"thread_local_#{self.name}_switch_point_name"] = name
      end

      private :thread_local_switch_point_name=

      def switch_point_proxy
        if switch_point_name
          ProxyRepository.checkout(switch_point_name)
        elsif self == ActiveRecord::Base
          nil
        else
          superclass.switch_point_proxy
        end
      end

      def transaction_with(*models, &block)
        unless can_transaction_with?(*models)
          raise Error.new("switch_point's model names must be consistent")
        end

        with_master do
          transaction(&block)
        end
      end

      private

      def assert_existing_switch_point!(name)
        SwitchConnection.config.fetch(name)
      end

      def can_transaction_with?(*models)
        master_switch_points = [self, *models].map do |model|
          next unless model.switch_point_name

          SwitchConnection.config.model_name(
            model.switch_point_name,
            :master
          )
        end

        master_switch_points.uniq.size == 1
      end
    end

    module MonkeyPatch
      def connection
        if switch_point_proxy
          connection = switch_point_proxy.connection
          connection.connection_name = "#{switch_point_name.to_s} #{switch_point_proxy.mode.to_s}"
          connection
        else
          super
        end
      end

      def cache(&block)
        if switch_point_proxy
          switch_point_proxy.cache(&block)
        else
          super
        end
      end

      def uncached(&block)
        if switch_point_proxy
          switch_point_proxy.uncached(&block)
        else
          super
        end
      end
    end

    module AutoReadFromSlave
      def find_by_sql(*args, &block)
        self.with_auto_slave do
          super(*args, &block)
        end
      end

      def count_by_sql(*args, &block)
        self.with_auto_slave do
          super(*args, &block)
        end
      end
    end
  end
end
