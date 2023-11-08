module SgFargateRails
  module BlazerQueriesController
    extend ActiveSupport::Concern

    prepended do
      before_action :require_sg_admin_if_blazer_danger_action!
    end

    def csv_data(columns, rows, data_source)
      # UTF-8のCSVをエクセルで文字化けせずに開くために先頭にBOMをつけている
      "\xEF\xBB\xBF#{super}"
    end

    # NOTE: 表示件数の上限を設定可能にしている https://github.com/ankane/blazer/pull/311
    def render_run
      row_limit = Blazer.settings.fetch('row_limit', 5000)
      if request.format == :html && row_limit
        @row_limit ||= row_limit
      end

      super
    end

    private

    def require_sg_admin_if_blazer_danger_action!
      return unless action_name.in?(%w[new edit create update destroy])
      unless blazer_sg_admin?
        Rails.logger.warn "BlazerQueriesController##{action_name} is called by non sg_admin (#{blazer_user&.class&.name}: #{blazer_user&.id})"
        render plain: '403 Forbidden', status: :forbidden
      end
    end

    def blazer_sg_admin?
      return false unless blazer_user

      blazer_user.respond_to?(:sg_admin?) ? blazer_user.sg_admin? : blazer_user.email.ends_with?('@sonicgarden.jp')
    end
  end
end
