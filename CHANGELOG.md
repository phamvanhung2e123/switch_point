## 1.1.0
- Add auto send read query to slave https://github.com/phamvanhung2e123/switch_point/pull/5

## 1.0.0 (2019-07-31)
- Multi slaves support
- Connect to master by default
- Change switch point (thread safe)
- Log connection name

## 0.8.0 (2016-06-06)
- Drop Ruby 2.0.0 and 2.1 support
- Add `AR::Base#with_readonly` and `AR::Base#with_writable`
    - short-hand for `AR::Base.with_readonly` and `AR::Base.with_writable`
- Add `AR::Base#transaction_with`
    - short-hand for `AR::Base.transaction_with`
- Fix warnings for Rails 5.0

## 0.7.0 (2015-10-16)
- `Model.with_readonly` and `Model.with_writable` now raises error when the Model doesn't use switch_point

## 0.6.0 (2015-04-14)
- Add `SwitchConnection::QueryCache` middleware
- `Model.cache` and `Model.uncached` is now hooked by switch_point
    - `Model.cache` enables query cache for both readonly and writable.
    - `Model.uncached` disables query cache for both readonly and writable.
- Add `SwitchConnection.with_readonly_all` and `SwitchConnection.with_writable_all` as shorthand

## 0.5.0 (2014-11-05)
- Rename `SwitchConnection.with_connection` to `SwitchConnection.with_mode`
    - To avoid confusion with `ActiveRecord::ConnectionPool#with_connection`
- Inherit superclass' switch_point configuration

## 0.4.4 (2014-07-14)
- Memorize switch_point config to ConnectionSpecification#config instead of ConnectionPool
    - To support multi-threaded environment since Rails 4.0.

## 0.4.3 (2014-06-24)
- Add Model.transaction_with method (#2, @ryopeko)

## 0.4.2 (2014-06-19)
- Establish connection lazily
    - Just like ActiveRecord::Base, real connection isn't created until `.connection` is called

## 0.4.1 (2014-06-19)
- Support :writable only configuration

## 0.4.0 (2014-06-17)
- auto_writable is disabled by default
    - To restore the previous behavior, set `config.auto_writable = true`.
- Add shorthand methods `SwitchConnection.with_readonly`, `SwitchConnection.with_writable`

## 0.3.1 (2014-06-04)
- Support defaulting to writable ActiveRecord::Base connection
    - When `:writable` key is omitted, ActiveRecord::Base is used for the writable connection.

## 0.3.0 (2014-06-04)
- Improve thread safety
- Raise appropriate error if unknown mode is given to with_connection

## 0.2.3 (2014-06-02)
- Support specifying the same database name within different switch_point
- Add Proxy#readonly? and Proxy#writable? predicate

## 0.2.2 (2014-05-30)
- Fix nil error on with_{readonly,writable} from non-switch_point model

## 0.2.1 (2014-05-29)
- Add Proxy#switch_name to switch proxy configuration
- Fix weird nil error when Config#define_switch_point isn't called yet

## 0.2.0 (2014-05-29)
- Always send destructive operations to writable connection
- Fix bug on pooled connections

## 0.1.0 (2014-05-28)
- Initial release
