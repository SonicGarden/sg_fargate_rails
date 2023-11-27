require 'sg_fargate_rails/adjust_cloudfront_headers'
require 'sg_fargate_rails/healthcheck'
require 'sg_fargate_rails/maintenance'
require 'sg_fargate_rails/remote_ip'
require 'sg_fargate_rails/task_protection'

module SgFargateRails
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path('../tasks/sg_fargate_rails.rake', __dir__)
    end

    initializer :initialize_sg_fargate_rails, after: :load_config_initializers do |app|
      if SgFargateRails.config.middleware_enabled
        app.config.middleware.insert 0, SgFargateRails::AdjustCloudfrontHeaders
        app.config.middleware.insert 1, SgFargateRails::Healthcheck
        app.config.middleware.swap ActionDispatch::RemoteIp, SgFargateRails::RemoteIp, app.config.action_dispatch.ip_spoofing_check, app.config.action_dispatch.trusted_proxies
        app.config.middleware.insert_after SgFargateRails::RemoteIp, SgFargateRails::Maintenance
      end

      if defined?(::Blazer)
        unless defined?(::Blazer::Plus)
          raise SgFargateRails::Error, 'Please install blazer-plus gem.'
        end

        Blazer::Plus.blazer_danger_actionable_method ||= ->(blazer_user) { blazer_user.email.ends_with?('@sonicgarden.jp') }
      end

      ActiveSupport.on_load(:good_job_application_controller) do
        before_action :sg_fargate_rails_proxy_access!, if: -> { SgFargateRails.config.restrict_access_to_good_job_dashboard }

        def sg_fargate_rails_proxy_access!
          unless SgFargateRails.config.proxy_access?(request.remote_ip)
            render plain: 'Forbidden', status: :forbidden
          end
        end
      end
    end
  end
end
