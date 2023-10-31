module SgFargateRails
  # NOTE: HTTP_CLOUDFRONT_VIEWER_ADDRESSを考慮するように上書きしている
  # SEE: https://github.com/rails/rails/blob/main/actionpack/lib/action_dispatch/middleware/remote_ip.rb
  class RemoteIp < ActionDispatch::RemoteIp
    def call(env)
      req = ActionDispatch::Request.new env
      # NOTE: HTTP_CLOUDFRONT_VIEWER_ADDRESSヘッダには127.0.0.1:3000といったIP4アドレスや2406:2d40:3090:af00:25c1:6071:b820:8e47:3000といったIP6アドレスが入っている
      req.remote_ip = req.headers['HTTP_CLOUDFRONT_VIEWER_ADDRESS'] ? req.headers['HTTP_CLOUDFRONT_VIEWER_ADDRESS'].remove(/:\d+$/) : ActionDispatch::RemoteIp::GetIp.new(req, check_ip, proxies)
      @app.call(req.env)
    end
  end
end
