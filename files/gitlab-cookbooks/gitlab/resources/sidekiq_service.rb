resource_name :sidekiq_service

property :rails_app
property :user
property :group

action :enable do
  svc = new_resource.name
  user = new_resource.user
  group = new_resource.group
  rails_app = new_resource.rails_app

  metrics_dir = ::File.join(node['gitlab']['runtime-dir'].to_s, 'gitlab/sidekiq') unless node['gitlab']['runtime-dir'].nil?

  sidekiq_log_dir = node['gitlab'][svc]['log_directory']

  directory sidekiq_log_dir do
    owner user
    mode '0700'
    recursive true
  end

  runit_service svc do
    start_down node['gitlab'][svc]['ha']
    template_name 'sidekiq'
    options({
      rails_app: rails_app,
      user: user,
      groupname: group,
      shutdown_timeout: node['gitlab'][svc]['shutdown_timeout'],
      concurrency: node['gitlab'][svc]['concurrency'],
      log_directory: sidekiq_log_dir,
      metrics_dir: metrics_dir,
      clean_metrics_dir: true
    }.merge(new_resource))
    log_options node['gitlab']['logging'].to_hash.merge(node['gitlab'][svc].to_hash)
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{svc}" do
      retries 20
    end
  end
end
