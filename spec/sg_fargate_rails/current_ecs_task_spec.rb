require 'spec_helper'

describe SgFargateRails::CurrentEcsTask do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('COPILOT_APPLICATION_NAME').and_return('test-project')
    allow(ENV).to receive(:[]).with('COPILOT_ENVIRONMENT_NAME').and_return('staging')
  end

  let(:ecs_task) { SgFargateRails::CurrentEcsTask.new }

  describe '#cfn_stack_name' do
    context 'Copilot CLI 環境の場合' do
      it 'スタック名が "test-project-staging" になること' do
        expect(ecs_task.cfn_stack_name).to eq 'test-project-staging'
      end
    end

    xcontext 'CFgen 環境の場合' do
      before do
        allow(ENV).to receive(:[]).with('CFGEN_ENABLED').and_return('true')
      end

      it 'スタック名が "cfgen-test-project-staging-environments" になること' do
        expect(ecs_task.cfn_stack_name).to eq 'cfgen-test-project-staging-environments'
      end
    end
  end

  xdescribe '#scheduler_group_name' do
    context 'Copilot CLI 環境の場合' do
      it 'Schedulerグループが "test-project-staging" になること' do
        expect(ecs_task.scheduler_group_name).to eq 'test-project-staging'
      end
    end

    context 'CFgen 環境の場合' do
      before do
        allow(ENV).to receive(:[]).with('CFGEN_ENABLED').and_return('true')
      end

      it 'Schedulerグループが "cfgen-test-project-staging" になること' do
        expect(ecs_task.scheduler_group_name).to eq 'cfgen-test-project-staging'
      end
    end
  end
end
