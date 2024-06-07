require 'spec_helper'

describe SgFargateRails::EventBridgeSchedule do

  describe '.input_overrides_json' do
    let(:cron) { 'cron(30 16 * * ? *)' }
    let(:command) { 'jobmon --estimate-time=3000 stat' }

    subject { schedule.input_overrides_json }

    context 'container_typeが指定されている場合' do
      let(:storage_size_gb) { 64 }
      let(:container_type) { 'medium' }
      let(:schedule) { SgFargateRails::EventBridgeSchedule.new(name: 'name', cron: cron, command: command, container_type: container_type, storage_size_gb: storage_size_gb) }

      it 'cpuやmemoryの情報が補完されること' do
        is_expected.to eq(
                         {
                           "cpu": "1024",
                           "memory": "2048",
                           "ephemeralStorage": { "sizeInGiB": 64 },
                           "containerOverrides": [
                             {
                               "name": "rails",
                               "cpu": "1024",
                               "memory": "2048",
                               "command": %w[bundle exec jobmon --estimate-time=3000 stat],
                             }
                           ]
                         }.to_json
                       )
      end
    end

    context 'container_typeが指定されていない場合' do
      let(:schedule) { SgFargateRails::EventBridgeSchedule.new(name: 'name', cron: cron, command: command) }

      it do
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
  end

  describe '.convert' do
    context 'scheduleの登録がない場合' do
      it do
        expect(SgFargateRails::EventBridgeSchedule.convert(nil)).to eq []
      end
    end

    context 'scheduleの登録が複数存在する場合' do
      let(:filename) { 'spec/fixtures/event_bridge_schedule/schedule.yml' }

      it do
        results = SgFargateRails::EventBridgeSchedule.convert({
          daily_backup_to_s3: {
            command: 'jobmon --estimate-time=3000 sg_tiny_backup:backup',
            cron: 'cron(30 1 * * ? *)',
            container_type: 'medium',
          }
        })
        expect(results.size).to eq 1
        expect(results.first.name).to eq 'daily_backup_to_s3'
      end
    end
  end

  describe '#container_command' do
    context 'use_bundler に false が指定された場合' do
      let(:schedule) { SgFargateRails::EventBridgeSchedule.new(name: 'test-task-name', cron: 'cron(30 16 * * ? *)', command: 'echo "Hello"', use_bundler: false) }

      it 'containerOverrides の command に bundle exec がつかない' do
        expect(schedule.container_command).to eq ['echo', '"Hello"']
      end
    end

    context 'command に配列が指定された場合' do
      let(:schedule) { SgFargateRails::EventBridgeSchedule.new(name: 'test-task-name', cron: 'cron(30 16 * * ? *)', command: ['rails', '-v']) }

      it 'containerOverrides の command に指定した配列が追加される' do
        expect(schedule.container_command).to eq ['bundle', 'exec', 'rails', '-v']
      end
    end

    context 'use_bundler に false, command に配列が指定された場合' do
      let(:schedule) { SgFargateRails::EventBridgeSchedule.new(name: 'test-task-name', cron: 'cron(30 16 * * ? *)', command: ['/bin/sh', '-c', 'echo', '"Hello World"'], use_bundler: false) }

      it 'containerOverrides の command に指定した配列がそのまま出力される' do
        expect(schedule.container_command).to eq ['/bin/sh', '-c', 'echo', '"Hello World"']
      end
    end
  end
end
