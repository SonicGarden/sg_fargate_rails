require 'rack/attack'

module SgFargateRails
  class RackAttack
    class << self
      def setup
        return if SgFargateRails.config.proxy_ip_addresses.empty?

        Rack::Attack.blocklist('allow only from proxy') do |req|
          ip_retricted_path?(req.path) && !proxy_access?(req)
        end
      end

      def ip_retricted_path?(path)
        rectricted_paths = Array(SgFargateRails.config.paths_to_allow_access_only_from_proxy || [])
        rectricted_paths.any? { path.match?(/^#{_1}/) }
      end

      def proxy_access?(req)
        SgFargateRails.config.proxy_access?(req.ip) || req.forwarded_for&.any? { |forwarded_for| SgFargateRails.config.proxy_access?(forwarded_for) }
      end
    end
  end
end
