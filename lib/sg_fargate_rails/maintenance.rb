require 'rack'
require 'rack/request'
require 'find'

module SgFargateRails
  class Maintenance
    def initialize(app, options = {})
      @app = app
    end

    def call(env)
      if maintenance_mode?(env) && !public_file_access?(env) && !proxy_access?(ActionDispatch::Request.new(env))
        headers = { 'Content-Type' => 'text/html' }
        [503, headers, File.open(maintenance_file_path)]
      else
        @app.call(env)
      end
    end

    private

    def maintenance_mode?(env)
      env['HTTP_X_SG_FARGATE_RAILS_MAINTENANCE'].present?
    end

    # NOTE: cloudfrontでcacheにヒットしなかった場合の対策用
    def public_file_access?(env)
      @public_files ||= public_files
      @public_files.include?(env['PATH_INFO'])
    end

    def public_files
      Find.find(Rails.root.join('public')).select { |f| File.file?(f) }.map { |f| f.remove(Rails.root.join('public').to_s) }
    end

    def maintenance_file_path
      Rails.public_path.join('503.html')
    end

    def proxy_access?(req)
      SgFargateRails.config.proxy_access?(req.remote_ip)
    end
  end
end
