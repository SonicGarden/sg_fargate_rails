require 'sg_fargate_rails/adjust_cloudfront_headers'
require 'sg_fargate_rails/healthcheck'
require 'sg_fargate_rails/maintenance'
require 'sg_fargate_rails/rack_attack'
require 'sg_fargate_rails/remote_ip'
require 'sg_fargate_rails/task_protection'

module SgFargateRails
  class Railtie < ::Rails::Railtie
    initializer :initialize_sg_fargate_rails do |app|
      unless ::Rails.env.in?(%w[development test])
        SgFargateRails::RackAttack.setup

        app.config.middleware.insert 0, SgFargateRails::AdjustCloudfrontHeaders
        app.config.middleware.insert 1, SgFargateRails::Healthcheck
        app.config.middleware.insert 2, SgFargateRails::Maintenance
        app.config.middleware.swap ActionDispatch::RemoteIp, SgFargateRails::RemoteIp, app.config.action_dispatch.ip_spoofing_check, app.config.action_dispatch.trusted_proxies
      end
    end
  end
end
