# SwitchConnection
[![Gem Version](https://badge.fury.io/rb/switch_connection.svg)](https://badge.fury.io/rb/switch_connection)
[![Build Status](https://travis-ci.org/phamvanhung2e123/switch_point.svg?branch=master)](https://travis-ci.org/phamvanhung2e123/switch_point)
[![Coverage Status](https://img.shields.io/coveralls/phamvanhung2e123/switch_point.svg?branch=master)](https://coveralls.io/r/phamvanhung2e123/switch_point?branch=master)
[![Code Climate](https://codeclimate.com/github/phamvanhung2e123/switch_point/badges/gpa.svg)](https://codeclimate.com/github/phamvanhung2e123/switch_point)

Switching database connection between multiple slave and writable one. Fork from `switch_point` gem.
Original Version: https://github.com/eagletmt/switch_point.

## Installation

Add this line to your application's Gemfile:

    gem 'switch_connection'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install switch_connection

## Usage
Suppose you have 4 databases: db-blog-master, db-blog-slave, db-comment-master and db-comment-slave.
Article model and Category model are stored in db-blog-{master,slave} and Comment model is stored in db-comment-{master,slave}.

### Configuration
In database.yml:

```yaml
production_blog_master:
  adapter: mysql2
  username: blog_writable
  host: db-blog-master
production_blog_slave:
  adapter: mysql2
  username: blog_slave
  host: db-blog-slave
production_comment_master:
    ...
```

In initializer:

```ruby
SwitchConnection.configure do |config|
  config.define_switch_point :blog,
    slaves: [:"#{Rails.env}_blog_slave1",:"#{Rails.env}_blog_slave2"]
    master: :"#{Rails.env}_blog_master"
  config.define_switch_point :comment,
    slaves: [:"#{Rails.env}_comment_slave"]
    master: :"#{Rails.env}_comment_master"
end
```

In models:

```ruby
class Article < ActiveRecord::Base
  use_switch_point :blog
end

class Category < ActiveRecord::Base
  use_switch_point :blog
end

class Comment < ActiveRecord::Base
  use_switch_point :comment
end
```

### Switching connections

```ruby
Article.first # Read from db-blog-slave
Category.first # Also read from db-blog-slave
Comment.first # Read from db-comment-slave

Article.with_master do
  article.save!  # Write to db-blog-master
  article.reload  # Read from db-blog-master
  Category.first  # Read from db-blog-master
end
```

- with_switch_point
```ruby
Book.with_switch_point(:main) { Book.count  }
```

Note that Article and Category shares their connections.

### Special case: ActiveRecord::Base.connection
Basically, each connection managed by a proxy isn't shared between proxies.
But there's one exception: ActiveRecord::Base.

## Contributing

1. Fork it ( https://github.com/phamvanmhung2e123/switch_point/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
