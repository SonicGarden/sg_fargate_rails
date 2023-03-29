require 'sg_fargate_rails/adjust_cloudfront_headers'
require 'sg_fargate_rails/healthcheck'

module SgFargateRails
  class Railtie < ::Rails::Railtie
    initializer :initialize_sg_fargate_rails do |app|
      unless ::Rails.env.in?(%w[development test])
        app.config.middleware.insert 0, SgFargateRails::AdjustCloudfrontHeaders
        app.config.middleware.insert 1, SgFargateRails::Healthcheck
      end
    end
  end
end
