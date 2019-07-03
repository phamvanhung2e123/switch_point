module SwitchPoint
  module LogSubscriber
    def self.included(base)
      base.send(:attr_accessor, :connection_name)
      base.prepend MonkeyPatch
    end

    module MonkeyPatch
      def sql(event)
        self.connection_name = event.payload[:connection_name]
        super
      end

      def debug(msg)
        conn = connection_name ? color("  [#{connection_name}]", ActiveSupport::LogSubscriber::BLUE, true) : ''
        super (conn + msg)
      end
    end
  end
end