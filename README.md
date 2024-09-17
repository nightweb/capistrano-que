[![Gem Version](https://badge.fury.io/rb/capistrano-que.svg)](http://badge.fury.io/rb/capistrano-que)

# Capistrano::Que

Que integration for Capistrano

## Installation

    gem 'capistrano-que', group: :development

And then execute:

    $ bundle


## Usage
```ruby
    # Capfile
    require 'capistrano/que'
    install_plugin Capistrano::Que  # Default que tasks
    # Then select your service manager
    install_plugin Capistrano::Que::Systemd
```

Configurable options - Please ensure you check your version's branch for the available settings - shown here with defaults:

```ruby
:que_roles => :worker
:que_default_hooks => true
:que_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
# single config
:que_queues, ['que.yml']
# multiple configs
:que_queues, ['que.yml', 'que-2.yml'] #  you can also set it per server
```

## Example

A sample application is provided to show how to use this gem at https://github.com/seuros/capistrano-example-app

## Configuring the log files on systems with less recent Systemd versions

The template used by this project assumes a recent version of Systemd (v240+, e.g. Ubuntu 20.04).

On systems with a less recent version, the `append:` functionality is not supported, and the Que log messages are sent to the syslog.

It's possible to workaround this limitation by configuring the system logger to filter the Que messages; see [wiki](/../../wiki/Configuring-append-mode-log-files-via-Syslog-NG).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
