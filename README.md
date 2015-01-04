ounce
=====

A minimal Ruby server, capable of serving a file tree and CSS files.

Installing
----------

Clone the repo and run `bundle install`.

Running
-------

From the command line:

```
ruby server.rb
```

To stop the server, hit `^C`.

From a script:

```
@server = Server.new
@server.serve
...
@server.stop
```

Tests
-----

```
rspec spec/
```

Known issues
------------

Using Firefox to test the server, as well as using Firefox as the default driver 
for Selenium Capybara specs, leads to unexpected 'Server busy errors'. We advise 
you to use Chrome when testing the server.

For configuring the specs to use the Chrome driver:

- add `gem 'chromedriver-helper'` in `Gemfile`;
- run `bundle install`
- add the following when configuring RSpec:

```
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end
```
