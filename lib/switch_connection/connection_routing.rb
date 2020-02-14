# frozen_string_literal: true

# This Module is for MonkeyPatch ActiveRecord::Relation
module SwitchConnection
  module Relation
    module MonkeyPatch
      def calculate(*args, &block)
        if @klass.switch_point_proxy && !lock_value && @klass.connection.open_transactions.zero?
          @klass.with_slave do
            super
          end
        else
          super
        end
      end

      def exists?(*args, &block)
        if @klass.switch_point_proxy && !lock_value && @klass.connection.open_transactions.zero?
          @klass.with_slave do
            super
          end
        else
          super
        end
      end

      def pluck(*args, &block)
        if @klass.switch_point_proxy && !lock_value && @klass.connection.open_transactions.zero?
          @klass.with_slave do
            super
          end
        else
          super
        end
      end
    end
  end
end
