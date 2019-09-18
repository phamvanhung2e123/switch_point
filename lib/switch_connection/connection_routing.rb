module SwitchConnection
  module ConnectionRouting

    # All the methods that could be querying the database
    SLAVE_METHODS = [:calculate, :exists?, :pluck]
    def calculate(*args, &block)
      if @klass.try(:switch_point_proxy)
        @klass.with_slave do
          super
        end
      else
        super
      end
    end

    def exists?(*args, &block)
      if @klass.try(:switch_point_proxy)
        @klass.with_slave do
          super
        end
      else
        super
      end
    end

    def pluck(*args, &block)
      if @klass.try(:switch_point_proxy)
        @klass.with_slave do
          super
        end
      else
        super
      end
    end
  end
end
