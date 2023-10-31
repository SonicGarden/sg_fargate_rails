require 'spec_helper'

describe SgFargateRails::EventBridgeSchedule do

  describe '.input_overrides_json' do
    let(:cron) { 'cron(30 16 * * ? *)' }
    let(:command) { 'jobmon --estimate-time=3000 stat' }
    let(:schedule) { SgFargateRails::EventBridgeSchedule.new('name', cron, command, container_type) }

    subject { schedule.input_overrides_json }

    context 'container_typeが指定されている場合' do
      let(:container_type) { 'small' }

      it 'cpuやmemoryの情報が補完されること' do
        is_expected.to eq(
                         {
                           "cpu": "512",
                           "memory": "1024",
                           "containerOverrides": [
                             {
                               "name": "rails",
                               "cpu": "512",
                               "memory": "1024",
                               "command": %w[bundle exec jobmon --estimate-time=3000 stat],
                             }
                           ]
                         }.to_json
                       )
      end
    end

    context 'container_typeが指定されていない場合' do
      let(:container_type) { nil }

      it do
        is_expected.to eq(
                         {
                           "containerOverrides": [
                             {
                               "name": "rails",
                               "command": %w[bundle exec jobmon --estimate-time=3000 stat],
                             }
                           ]
                         }.to_json
                       )
      end
    end
  end
end