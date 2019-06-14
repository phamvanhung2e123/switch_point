# frozen_string_literal: true
require 'pry'
module SwitchPoint
  class Config
    attr_accessor :auto_master, :env
    alias_method :auto_master?, :auto_master

    def initialize
      self.auto_master = false
      self.env = :test
    end

    def define_switch_point(name, config)
      assert_valid_config!(config)
      switch_points[name] = config
    end

    def switch_points
      @switch_points ||= {}
    end

    def master_database_name(name)
      fetch(name)[:master]
    end

    def slave_database_name(name, index)
      fetch(name)[:slaves][index]
    end

    def model_name(name, mode)
      if mode == :master
        master_model_name(name)
      else
        return unless slave_exist?(name)
        slave_mode_name(name, rand(slave_count(name)))
      end
    end

    def master_model_name(name)
      if fetch(name)[:master]
        "#{name}_master".camelize
      end
    end

    def slave_mode_name(name, index)
      "#{name}_slave_index_#{index}".camelize
    end

    def slave_exist?(name)
      fetch(name).key?(:slaves)
    end

    def slave_count(name)
      return 0 unless slave_exist?(name)
      fetch(name)[:slaves].count
    end

    def slave_mode_names(name)
      (0..(fetch(name)[:slaves].count-1)).map { |i| slave_mode_name(name, i)  }
    end

    def fetch(name)
      switch_points.fetch(name)
    end

    def keys
      switch_points.keys
    end

    def each_key(&block)
      switch_points.each_key(&block)
    end

    private

    def assert_valid_config!(config)
      unless config.key?(:master) || config.key?(:slaves)
        raise ArgumentError.new(':master or :slaves must be specified')
      end
      if config.key?(:slaves)
        unless config[:slaves].is_a?(Array)
          raise TypeError.new(":slaves's value must be Array")
        end
      end
      if config.key?(:master)
        unless config[:master].is_a?(Symbol)
          raise TypeError.new(":master's value must be ")
        end
      end
      nil
    end
  end
end
