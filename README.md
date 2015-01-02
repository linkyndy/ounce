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
