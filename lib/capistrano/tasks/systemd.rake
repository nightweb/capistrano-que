# frozen_string_literal: true

git_plugin = self

namespace :que do
  standard_actions = {
    start: 'Start Que',
    stop: 'Stop Que (graceful shutdown within timeout, put unfinished tasks back to Redis)',
    status: 'Get Que Status',
    restart: 'Restart Que'
  }
  standard_actions.each do |command, description|
    desc description
    task command do
      on roles fetch(:que_roles) do |role|
        git_plugin.switch_user(role) do
          git_plugin.queues(role).each do |queue|
            git_plugin.execute_systemd(command, git_plugin.que_service_file_name(queue))
          end
        end
      end
    end
  end

  desc 'Quiet Que (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:que_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_que(role)
      end
    end
  end

  desc 'Install Que systemd service'
  task :install do
    on roles fetch(:que_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.create_systemd_template(role)
      end
    end
    invoke 'que:enable'
  end

  desc 'Uninstall Que systemd service'
  task :uninstall do
    invoke 'que:disable'
    on roles fetch(:que_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.rm_systemd_service(role)
      end
    end
  end

  desc 'Enable Que systemd service'
  task :enable do
    on roles(fetch(:que_roles)) do |role|
      git_plugin.queues(role).each do |queue|
        git_plugin.execute_systemd("enable", git_plugin.que_service_file_name(queue))
      end

      if fetch(:systemctl_user) && fetch(:que_lingering_user)
        execute :loginctl, "enable-linger", fetch(:puma_lingering_user)
      end
    end
  end

  desc 'Disable Que systemd service'
  task :disable do
    on roles(fetch(:que_roles)) do |role|
      git_plugin.queues(role).each do |queue|
        git_plugin.execute_systemd("disable", git_plugin.que_service_file_name(queue))
      end
    end
  end

  def fetch_systemd_unit_path
    if fetch(:puma_systemctl_user) == :system
      "/etc/systemd/system/"
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, ".config", "systemd", "user")
    end
  end

  def create_systemd_template(role)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    backend.execute :mkdir, '-p', systemd_path if fetch(:systemctl_user)

    queues(role).each do |queue|
        ctemplate = compiled_template(queue)
        temp_file_name = File.join('/tmp', "que.#{queue}.service")
        systemd_file_name = File.join(systemd_path, que_service_file_name(queue))
        backend.upload!(StringIO.new(ctemplate), temp_file_name)
        if fetch(:systemctl_user)
          warn "Moving #{temp_file_name} to #{systemd_file_name}"
          backend.execute :mv, temp_file_name, systemd_file_name
        else
          warn "Installing #{systemd_file_name} as root"
          backend.execute :sudo, :mv, temp_file_name, systemd_file_name
        end
    end
  end

  def rm_systemd_service(role)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)

    queues(role).each do |queue|
      systemd_file_name = File.join(systemd_path, que_service_file_name(queue))
      if fetch(:systemctl_user)
        warn "Deleting #{systemd_file_name}"
        backend.execute :rm, "-f", systemd_file_name
      else
        warn "Deleting #{systemd_file_name} as root"
        backend.execute :sudo, :rm, "-f", systemd_file_name
      end
    end
  end

  def quiet_que(role)
    queues(role).each do |queue|
      que_service = que_service_unit_name(queue)
      warn "Quieting #{que_service}"
      execute_systemd("kill -s TSTP", que_service)
    end
  end

  def que_service_unit_name(queue)
    if queue != "que.yml"
      fetch(:que_service_unit_name) + "." + queue.split(".")[0..-2].join(".")
    else
      fetch(:que_service_unit_name)
    end
  end

  def que_service_file_name(queue)
    ## Remove the extension
    queue = queue.split('.')[0..-1].join('.')

    "#{que_service_unit_name(queue)}.service"
  end

  def queues(role)
    role.properties.fetch(:que_queues) ||
      fetch(:que_queues)
  end
end
