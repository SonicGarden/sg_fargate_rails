module SgFargateRails
  class Config
    attr_reader :proxy_ip_addresses
    attr_accessor :middleware_enabled
    attr_accessor :scheduled_state_machine_enabled

    # NOTE: good_jobダッシュボードへのアクセスをproxy経由のアクセスに制限するかどうか
    attr_accessor :restrict_access_to_good_job_dashboard

    def initialize
      self.proxy_ip_addresses = ENV['SG_PROXY_IP_ADDRESSES']
      self.restrict_access_to_good_job_dashboard = Rails.env.production?
      self.middleware_enabled = !Rails.env.development? && !Rails.env.test?

      # NOTE: このオプションは近い将来にデフォルト true へ変更、最終的に削除される予定
      self.scheduled_state_machine_enabled = false
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
