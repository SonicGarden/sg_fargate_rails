module SgFargateRails
  class Config
    attr_accessor :proxy_ip_address, :paths_to_allow_access_only_from_proxy

    def initialize
      self.proxy_ip_address = ENV['SG_PROXY_IP_ADDRESS']
    end
  end
end
