require 'rack/attack'

module SgFargateRails
  class RackAttack
    class << self
      def setup
        Rack::Attack.blocklist('allow only from proxy') do |req|
          proxy_ip_addr = SgFargateRails.config.proxy_ip_address
          return false unless proxy_ip_addr

          p ['DEBUG', 'req.env[remote_addr]', req.env['REMOTE_ADDR'], 'req.ip=', req.ip]
          ip_retricted_path?(req.path) && proxy_ip_addr != req.ip
        end
      end

      def ip_retricted_path?(path)
        rectricted_paths = Array(SgFargateRails.config.paths_to_allow_access_only_from_proxy || [])
        rectricted_paths.any? { path.match?(/^#{_1}/) }
      end
    end
  end
end
