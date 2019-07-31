# frozen_string_literal: true

require 'singleton'
require 'switch_connection/proxy'

module SwitchConnection
  class ProxyRepository
    include Singleton

    def self.checkout(name)
      instance.checkout(name)
    end

    def self.find(name)
      instance.find(name)
    end

    def checkout(name)
      proxies[name] ||= Proxy.new(name)
    end

    def find(name)
      proxies.fetch(name)
    end

    def proxies
      @proxies ||= {}
    end
  end
end
