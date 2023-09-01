module SgFargateRails
  class Config
    attr_accessor :proxy_ip_addresses, :paths_to_allow_access_only_from_proxy

    def initialize
      self.proxy_ip_addresses = ENV['SG_PROXY_IP_ADDRESSES']
    end
  end
end
