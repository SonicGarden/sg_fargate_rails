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

  describe '#parse' do
    context 'scheduleの登録がない場合' do
      let(:filename) { 'spec/fixtures/event_bridge_schedule/blank_schedule.yml' }

      it do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RAILS_ENV').and_return('staging')

        expect(SgFargateRails::EventBridgeSchedule.parse(filename)).to eq [nil]
      end
    end

    context 'scheduleの登録が複数存在する場合' do
      let(:filename) { 'spec/fixtures/event_bridge_schedule/schedule.yml' }

      it do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RAILS_ENV').and_return('staging')

        results = SgFargateRails::EventBridgeSchedule.parse(filename)
        expect(results.size).to eq 1
        expect(results.first.name).to eq 'daily_backup_to_s3'
      end
    end
  end
end
