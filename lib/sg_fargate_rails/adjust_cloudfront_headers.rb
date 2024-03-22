module SgFargateRails
  class AdjustCloudfrontHeaders
    def initialize(app)
      @app = app
    end

    def call(env)
      proto = env['HTTP_CLOUDFRONT_FORWARDED_PROTO'].to_s
      if proto && proto.length > 0
        env['HTTP_X_FORWARDED_PROTO'] = 'https'
      else
        env['HTTP_X_FORWARDED_PROTO'] = 'http'
      end
      @app.call(env)
    end
  end
end
