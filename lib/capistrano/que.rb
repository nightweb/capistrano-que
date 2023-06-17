# frozen_string_literal: true

require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  module QueCommon
    def compiled_template(queue = "default")
      @queue = queue
      local_template_directory = fetch(:que_service_templates_path)
      search_paths = [
        File.join(local_template_directory, 'que.service.capistrano.erb'),
        File.expand_path(
          File.join(*%w[.. templates que.service.capistrano.erb]),
          __FILE__
        )
      ]
      template_path = search_paths.detect { |path| File.file?(path) }
      template = File.read(template_path)
      ERB.new(template, trim_mode: '-').result(binding)
    end

    def expanded_bundle_path
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end

    def que_config
      "-q #{@queue}" if @queue != "default"
    end

    def switch_user(role, &block)
      su_user = que_user(role)
      if su_user == role.user
        yield
      else
        as su_user, &block
      end
    end

    def que_user(role = nil)
      if role.nil?
        fetch(:que_user)
      else
        properties = role.properties
        properties.fetch(:que_user) || # local property for que only
          fetch(:que_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
      end
    end
  end
  class Que < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path('tasks/que.rake', __dir__)
    end

    def set_defaults
      set_if_empty :que_default_hooks, true

      set_if_empty :que_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:rake_env, fetch(:stage)))) }
      set_if_empty :que_roles, fetch(:que_role, :worker)

      set_if_empty :que_log, -> { File.join(shared_path, 'log', 'que.log') }
      set_if_empty :que_error_log, -> { File.join(shared_path, 'log', 'que.log') }

      set_if_empty :que_queues, ['default']

      # Rbenv, Chruby, and RVM integration
      append :rbenv_map_bins, 'que'
      append :rvm_map_bins, 'que'
      append :chruby_map_bins, 'que'
      # Bundler integration
      append :bundle_bins, 'que'
    end
  end
end

require_relative 'que/systemd'
