require 'net/http'
require 'json'
require 'aws-sdk-ec2'

module SgFargateRails
  class CurrentEcsTask
    def cluster_arn
      metadata[:Cluster]
    end

    def task_definition_arn
      "#{cluster_arn.split(":cluster/")[0]}:task-definition/#{metadata[:Family]}:#{metadata[:Revision]}"
    end

    def cfn_stack_name
      "#{ENV['COPILOT_APPLICATION_NAME']}-#{ENV['COPILOT_ENVIRONMENT_NAME']}"
    end

    def security_group_ids
      @security_group_ids ||= fetch_security_group_ids
    end

    def public_subnet_ids
      @public_subnet_ids ||= fetch_public_subnet_ids
    end

    private

    def metadata
      @metadata ||= begin
                      response = Net::HTTP.get(URI.parse("#{ENV['ECS_CONTAINER_METADATA_URI']}/task"))
                      JSON.parse(response, symbolize_names: true)
                    end
    end

    def region
      ENV['AWS_REGION'] || 'ap-northeast-1'
    end

    def ec2_client
      @ec2_client ||= Aws::EC2::Client.new(region: region, credentials: credentials)
    end

    def credentials
      @credentials ||= Aws::ECSCredentials.new(retries: 3)
    end

    def fetch_security_group_ids
      security_group_params = {
        filters: [
          {
            name: 'tag:aws:cloudformation:logical-id',
            values: ['EnvironmentSecurityGroup'],
          },
          {
            name: 'tag:aws:cloudformation:stack-name',
            values: [cfn_stack_name],
          }
        ],
      }
      resp = ec2_client.describe_security_groups(security_group_params)
      resp.to_h[:security_groups].map { |group| group[:group_id] }
    end

    def fetch_public_subnet_ids
      subnet_params = {
        filters: [
          {
            name: 'tag:aws:cloudformation:logical-id',
            values: %w[PublicSubnet1 PublicSubnet2],
          },
          {
            name: 'tag:aws:cloudformation:stack-name',
            values: [cfn_stack_name],
          },
        ],
      }
      resp = ec2_client.describe_subnets(subnet_params)
      resp.to_h[:subnets].map { |subnet| subnet[:subnet_id] }
    end
  end
end
