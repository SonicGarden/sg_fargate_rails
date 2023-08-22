require 'rack/attack'

module SgFargateRails
  class RackAttack
    class << self
      def setup
        proxy_ip_addresses_str = SgFargateRails.config.proxy_ip_address || ''
        proxy_ip_addresses = proxy_ip_addresses_str.split(',').map(&:strip).reject(&:blank?)
        return if proxy_ip_addresses.empty?

        Rack::Attack.blocklist('allow only from proxy') do |req|
          ip_retricted_path?(req.path) && !access_from?(req, proxy_ip_addresses)
        end
      end

      def ip_retricted_path?(path)
        rectricted_paths = Array(SgFargateRails.config.paths_to_allow_access_only_from_proxy || [])
        rectricted_paths.any? { path.match?(/^#{_1}/) }
      end

      def access_from?(req, proxy_ip_addresses)
        proxy_ip_addresses.any? do |proxy_ip_address|
          req.ip == proxy_ip_address || req.forwarded_for&.include?(proxy_ip_address)
        end
      end
    end
  end
end
