require 'rack/attack'

module SgFargateRails
  class RackAttack
    class << self
      def setup
        setup_trusted_proxies
        setup_allow_only_from_proxy
      end

      def setup_trusted_proxies
        Rails.application.configure do
          response_body = Net::HTTP.get(URI('https://ip-ranges.amazonaws.com/ip-ranges.json'))
          ip_ranges = JSON.parse(response_body)
          cloudfront_ips = ip_ranges['prefixes']
                             .select { |v| v['service'] == 'CLOUDFRONT' }
                             .map { |v| IPAddr.new(v['ip_prefix']) } +
                           ip_ranges['ipv6_prefixes']
                             .select { |v| v['service'] == 'CLOUDFRONT' }
                             .map { |v| IPAddr.new(v['ipv6_prefix']) }

          config.action_dispatch.trusted_proxies = cloudfront_ips
        end
      end

      def setup_allow_only_from_proxy
        Rack::Attack.blocklist('allow only from proxy') do |req|
          proxy_ip_addr = SgFargateRails.config.proxy_ip_address
          return false unless proxy_ip_addr

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
