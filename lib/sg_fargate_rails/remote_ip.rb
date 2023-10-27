module SgFargateRails
  # NOTE: HTTP_CLOUDFRONT_VIEWER_ADDRESSを考慮するように上書きしている
  # SEE: https://github.com/rails/rails/blob/main/actionpack/lib/action_dispatch/middleware/remote_ip.rb
  class RemoteIp < ActionDispatch::RemoteIp
    def call(env)
      req = ActionDispatch::Request.new env
      req.remote_ip = req.headers['HTTP_CLOUDFRONT_VIEWER_ADDRESS'] ? req.headers['HTTP_CLOUDFRONT_VIEWER_ADDRESS'].split(':').first : ActionDispatch::RemoteIp::GetIp.new(req, check_ip, proxies)
      @app.call(req.env)
    end
  end
end
