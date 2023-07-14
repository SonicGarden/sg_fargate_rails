require 'rack/attack'

module SgFargateRails
  class RackAttack
    class << self
      def setup
        Rack::Attack.blocklist('allow only from proxy') do |req|
          proxy_ip_addr = SgFargateRails.config.proxy_ip_address
          next false unless proxy_ip_addr

          ip_retricted_path?(req.path) && !access_from?(req, proxy_ip_addr)
        end
      end

      def ip_retricted_path?(path)
        rectricted_paths = Array(SgFargateRails.config.paths_to_allow_access_only_from_proxy || [])
        rectricted_paths.any? { path.match?(/^#{_1}/) }
      end

      def access_from?(req, proxy_ip_addr)
        req.ip == proxy_ip_addr || req.forwarded_for&.include?(proxy_ip_addr)
      end
    end
  end
end
