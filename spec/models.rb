# frozen_string_literal: true

require 'pry'
SwitchConnection.configure do |config|
  config.define_switch_point :main,
                             slaves: [:main_slave],
                             master: :main_master
  config.define_switch_point :main2,
                             slaves: [:main2_slave],
                             master: :main2_master
  config.define_switch_point :user,
                             slaves: [:user],
                             master: :user
  config.define_switch_point :comment,
                             slaves: [:comment_slave],
                             master: :comment_master
  config.define_switch_point :special,
                             slaves: [:main_slave_special],
                             master: :main_master
  config.define_switch_point :nanika1,
                             slaves: [:main_slave],
                             master: :main_master
  config.define_switch_point :nanika2,
                             slaves: [:main_slave],
                             master: :main_master
  config.define_switch_point :nanika3,
                             master: :comment_master
end

require 'active_record'

class Book < ActiveRecord::Base
  use_switch_point :main
  after_save :do_after_save

  private

  def do_after_save; end
end

class Book2 < ActiveRecord::Base
  use_switch_point :main
end

class Book3 < ActiveRecord::Base
  use_switch_point :main2
end

class Publisher < ActiveRecord::Base
  use_switch_point :main
end

class Comment < ActiveRecord::Base
  use_switch_point :comment
end

class User < ActiveRecord::Base
  use_switch_point :user
end

class BigData < ActiveRecord::Base
  use_switch_point :special
end

class Note < ActiveRecord::Base
end

class Nanika1 < ActiveRecord::Base
  use_switch_point :nanika1
end

class Nanika2 < ActiveRecord::Base
  use_switch_point :nanika2
end

class Nanika3 < ActiveRecord::Base
  use_switch_point :nanika3
end

class AbstractNanika < ActiveRecord::Base
  use_switch_point :main
  self.abstract_class = true
end

class DerivedNanika1 < AbstractNanika
end

class DerivedNanika2 < AbstractNanika
  use_switch_point :main2
end

base =
  if RUBY_PLATFORM == 'java'
    { adapter: 'jdbcsqlite3' }
  else
    { adapter: 'sqlite3', pool: 10 }
  end

databases = {
  test: {
    'main_slave' => base.merge(database: 'main_slave.sqlite3'),
    'main_master' => base.merge(database: 'main_master.sqlite3'),
    'main2_slave' => base.merge(database: 'main2_slave.sqlite3'),
    'main2_master' => base.merge(database: 'main2_master.sqlite3'),
    'main_slave_special' => base.merge(database: 'main_slave_special.sqlite3'),
    'user' => base.merge(database: 'user.sqlite3'),
    'comment_slave' => base.merge(database: 'comment_slave.sqlite3'),
    'comment_master' => base.merge(database: 'comment_master.sqlite3'),
    'default' => base.merge(database: 'default.sqlite3')
  }
}
ActiveRecord::Base.configurations =
  # ActiveRecord.gem_version was introduced in ActiveRecord 4.0
  if ActiveRecord.respond_to?(:gem_version) && ActiveRecord.gem_version >= Gem::Version.new('5.1.0')
    { 'test' => databases }
  else
    databases
  end

default_database_config = ActiveRecord::Base.configurations[SwitchConnection.config.env]['default']
ActiveRecord::Base.establish_connection(default_database_config)

# XXX: Check connection laziness
[Book, User, Note, Nanika1, ActiveRecord::Base].each do |model|
  if model.connected?
    raise "ActiveRecord::Base didn't establish connection lazily!"
  end
end
ActiveRecord::Base.connection # Create connection

[Book, User, Nanika3].each do |model|
  model.with_master do
    if model.switch_point_proxy.connected?
      raise "#{model.name} didn't establish connection lazily!"
    end
  end
  model.with_slave do
    if model.switch_point_proxy.connected?
      raise "#{model.name} didn't establish connection lazily!"
    end
  end
end

module SwitchConnection
  module LogSubscriber
    def self.included(base)
      base.send(:attr_accessor, :connection_name)
      base.send(:alias_method, :sql_without_connection_name, :sql)
      base.send(:alias_method, :sql, :sql_with_connection_name)

      base.send(:alias_method, :debug_without_connection_name, :debug)
      base.send(:alias_method, :debug, :debug_with_connection_name)
    end

    def sql_with_connection_name(event)
      self.connection_name = event.payload[:connection_name]
      sql_without_connection_name(event)
    end

    def debug_with_connection_name(msg)
      conn = connection_name ? color("  [#{connection_name}]", ActiveSupport::LogSubscriber::BLUE, true) : ''
      debug_without_connection_name(conn + msg)
    end
  end
end

ActiveRecord::LogSubscriber.include(SwitchConnection::LogSubscriber)
require 'logger'
ActiveRecord::Base.logger = Logger.new STDOUT
