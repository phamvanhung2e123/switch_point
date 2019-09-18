# frozen_string_literal: true

require 'switch_connection/error'

module SwitchConnection
  class Proxy
    attr_reader :initial_name

    AVAILABLE_MODES = %i[master slave].freeze
    DEFAULT_MODE = :master

    def initialize(name)
      @initial_name = name
      @current_name = name
      define_master_model(name)
      define_slave_model(name)
      @global_mode = DEFAULT_MODE
    end

    def define_master_model(name)
      model_name = SwitchConnection.config.master_model_name(name)
      if model_name
        model = Class.new(ActiveRecord::Base)
        Proxy.const_set(model_name, model)
        master_database_name = SwitchConnection.config.master_database_name(name)
        model.establish_connection(db_specific(master_database_name))
        model
      else
        ActiveRecord::Base
      end
    end

    def define_slave_model(name)
      return unless SwitchConnection.config.slave_exist?(name)

      slave_count = SwitchConnection.config.slave_count(name)
      (0..(slave_count - 1)).map do |index|
        model_name = SwitchConnection.config.slave_mode_name(name, index)
        next ActiveRecord::Base unless model_name

        model = Class.new(ActiveRecord::Base)
        Proxy.const_set(model_name, model)
        model.establish_connection(db_specific(SwitchConnection.config.slave_database_name(name, index)))
        model
      end
    end

    def db_specific(db_name)
      base_config = ::ActiveRecord::Base.configurations.fetch(SwitchConnection.config.env)
      return base_config if db_name == :default

      db_name.to_s.split('.').inject(base_config) { |h, n| h[n] }
    end

    def thread_local_mode
      Thread.current[:"switch_point_#{@current_name}_mode"]
    end

    def thread_local_mode=(mode)
      Thread.current[:"switch_point_#{@current_name}_mode"] = mode
    end
    private :thread_local_mode=

    def mode
      thread_local_mode || @global_mode
    end

    def switch_connection_levels
      Thread.current[:switch_connection_levels] ||= Hash.new(0)
    end

    def switch_connection_level=(level)
      switch_connection_levels[@current_name] = level
    end

    def switch_connection_level
      switch_connection_levels[@current_name] || 0
    end

    def switch_top_level_connection?
      switch_connection_level.zero?
    end

    def slave!
      if thread_local_mode
        self.thread_local_mode = :slave
      else
        @global_mode = :slave
      end
    end

    def slave?
      mode == :slave
    end

    def master!
      if thread_local_mode
        self.thread_local_mode = :master
      else
        @global_mode = :master
      end
    end

    def master?
      mode == :master
    end

    def with_slave(&block)
      with_mode(:slave, &block)
    end

    def with_master(&block)
      with_mode(:master, &block)
    end

    def with_mode(new_mode, &block)
      unless AVAILABLE_MODES.include?(new_mode)
        raise ArgumentError.new("Unknown mode: #{new_mode}")
      end

      saved_mode = thread_local_mode
      if (new_mode == :master) || (new_mode == :slave && switch_top_level_connection?)
        self.thread_local_mode = new_mode
      end
      self .switch_connection_level += 1
      block.call
    ensure
      self.thread_local_mode = saved_mode
      self .switch_connection_level -= 1
    end

    def switch_name(new_name, &block)
      if block
        begin
          old_name = @current_name
          @current_name = new_name
          block.call
        ensure
          @current_name = old_name
        end
      else
        @current_name = new_name
      end
    end

    def reset_name!
      @current_name = @initial_name
    end

    def model_for_connection
      ProxyRepository.checkout(@current_name) # Ensure the target proxy is created
      model_name = SwitchConnection.config.model_name(@current_name, mode)
      if model_name
        Proxy.const_get(model_name)
      elsif mode == :slave
        # When only master is specified, re-use master connection.
        with_master do
          model_for_connection
        end
      else
        ActiveRecord::Base
      end
    end

    def connection
      model_for_connection.connection
    end

    def connected?
      model_for_connection.connected?
    end

    def cache(&block)
      r = with_slave { model_for_connection }
      w = with_master { model_for_connection }
      r.cache { w.cache(&block) }
    end

    def uncached(&block)
      r = with_slave { model_for_connection }
      w = with_master { model_for_connection }
      r.uncached { w.uncached(&block) }
    end
  end
end
