module SgFargateRails
  class Config
    attr_accessor :paths_to_allow_access_only_from_proxy
    attr_reader :proxy_ip_addresses

    def initialize
      self.proxy_ip_addresses = ENV['SG_PROXY_IP_ADDRESSES']
    end

    def proxy_ip_addresses=(ip_addresses)
      @proxy_ip_addresses = Array(ip_addresses).flat_map do |ip_address_str|
        ip_address_str.split(',').map(&:strip).reject(&:blank?).map { |ip| IPAddr.new(ip) }
      end
    end

    def proxy_access?(ip_address)
      @proxy_ip_addresses.any? { |proxy_ip_address| proxy_ip_address.include?(ip_address) }
    end
  end
end
