# frozen_string_literal: true

require 'benchmark/ips'
require 'switch_point'
require 'active_record'
SwitchPoint.configure do |config|
  config.define_switch_point :proxy,
                             slaves: [:proxy_slave],
                             master: :proxy_master
end
ENV['RAILS_ENV'] ||= 'test'
class Plain < ActiveRecord::Base
end

class Proxy1 < ActiveRecord::Base
  use_switch_point :proxy
end

class ProxyBase < ActiveRecord::Base
  self.abstract_class = true
  use_switch_point :proxy
end

class Proxy2 < ProxyBase
end

database_config = { adapter: 'sqlite3', database: ':memory:' }
databases = {
  test: {
    'default' => database_config.dup,
    'proxy_slave' => database_config.dup,
    'proxy_master' => database_config.dup
  }
}

ActiveRecord::Base.configurations =
  # ActiveRecord.gem_version was introduced in ActiveRecord 4.0
  if ActiveRecord.respond_to?(:gem_version) && ActiveRecord.gem_version >= Gem::Version.new('5.1.0')
    { 'test' => databases }
  else
    databases
  end
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[SwitchPoint.config.env]['default'])

Plain.connection.execute('CREATE TABLE plains (id integer primary key autoincrement)')
%i[slave master].each do |mode|
  ProxyBase.public_send("with_#{mode}") do
    %w[proxy1s proxy2s].each do |table|
      ProxyBase.connection.execute("CREATE TABLE #{table} (id integer primary key autoincrement)")
    end
  end
end

Benchmark.ips do |x|
  x.report('plain') do
    Plain.create
    Plain.first
  end

  x.report('proxy1') do
    Proxy1.with_master { Proxy1.create }
    Proxy1.first
  end

  x.report('proxy2') do
    Proxy2.with_master { Proxy2.create }
    Proxy2.first
  end

  x.compare!
end
