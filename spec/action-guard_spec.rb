require 'spec_helper'

RSpec::Matchers.define :authorize do |account| 
  chain :to_perform_action do |request|
    @request = a_request_for(request)
  end
  match do |actual_guard| 
    actual_guard.authorized?(account, @request)
  end
end

describe ActionGuard do
  let (:guard) { ActionGuard::Guard.new }


  def a_request_for(path)
    request_params_for(path)
  end

  def request_params_for(path)
    path, parameters = path.split("?")
    controller, action = path.split('#')
    parameters_hash = Hash[ parameters &&  parameters.split("&").map {|key_value| key_value.split('=').map{|e| e.strip }} || [] ]
    parameters_hash['controller'] = controller
    parameters_hash['action'] = action || 'index'
    parameters_hash
  end

  def account_with_role(role)
      return stub(:account,:role => role.to_s)
  end

  describe "valid_role" do
    before do 
      guard.define_role :god, 0
    end

    it "is true when the roles is defined" do
      guard.valid_role?(:god).should be_true
      guard.valid_role?('god').should be_true

    end
    it "is fals when the role is not defined" do
      guard.valid_role?(:biker).should_not be_true
    end

    it "returns the valid roles on request" do
      guard.valid_roles.should == ['god']
    end
  end

  describe "role" do
    before do 
      guard.define_role :god, 0
      guard.define_role :admin, 1
    end

    describe ">=" do
      it "should be true when role level is lower" do
        guard.role(:god).should >= guard.role(:admin)
      end
      it "should be true when role level is equal" do
        guard.role(:god).should >= guard.role(:god)
      end
      it "should be false when role level is higher" do
        guard.role(:admin).should_not >= guard.role(:god)
      end
    end
    describe "<" do
      it "should be true when role level is higher" do
        guard.role(:admin).should < guard.role(:god)
      end
      it "should be true when role level is equal" do
        guard.role(:admin).should_not < guard.role(:admin)
      end
      it "should be false when role level is lower" do
        guard.role(:god).should_not < guard.role(:admin)
      end
    end
  end

  describe "defining a rule" do
    it "fails when role not defined" do
      lambda {
        guard.leveled_rule 'some_controller#some_action', :biker
      }.should raise_error ActionGuard::Error
    end

    it "fails when role not defined" do
      guard.define_role(:god, 0)
      lambda {
        guard.leveled_rule 'some_controller/some_action', :god, :biker
      }.should raise_error ActionGuard::Error
    end

    it "passes when role defined" do
      lambda {
        guard.define_role :biker, 0
        guard.leveled_rule 'some_controller#some_action', :biker
      }.should_not raise_error ActionGuard::Error
    end
  end

  describe "authorization when no rules defined" do
    it "raises error on trying to authorize" do
      lambda {
        guard.authorized?(account_with_role(:admin), 'some_controller#some_action')
      }.should raise_error ActionGuard::Error
    end
  end

  describe "authorization"  do
    before do
      guard.define_role :god, 0
      guard.define_role :king, 1
      guard.define_role :admin, 2
      guard.define_role :worker, 3
    end

    describe "on an allowance rule" do
      before do
        guard.allow_rule 'home'
      end
      it "allows" do
        guard.should authorize(account_with_role(:worker)).to_perform_action('home')
      end
      it "allows regardless of account" do
        guard.should authorize(nil).to_perform_action('home')
      end
    end

    describe "on an allowance rule with a block" do 
      let!(:mock_block_body) { mock }

      before do
        guard.allow_rule('some_controller#some_action') do |*args|
          mock_block_body.block_called(*args)
        end
      end

      it "calls block" do
        account = account_with_role(:worker)
        mock_block_body.should_receive(:block_called).with(account, request_params_for('some_controller#some_action'))
        guard.authorized?(account, a_request_for( 'some_controller#some_action'))
      end

      it "disallows when block returns false" do
        account = account_with_role(:worker)

        mock_block_body.stub(:block_called).and_return false

        guard.authorized?(account, a_request_for('some_controller#some_action')).should be_false
      end

      it "allows when block returns true" do
        account = account_with_role(:worker)

        mock_block_body.stub(:block_called).and_return true

        guard.authorized?(account, a_request_for('some_controller#some_action')).should be_true
      end
    end


    describe "on an exact rule" do
      before do
        guard.exact_role_rule 'home', :admin
      end
      it "allows if role matches" do
        guard.should authorize(account_with_role(:admin)).to_perform_action( 'home')
      end
      it "allows if role is a string" do
        guard.should authorize(account_with_role('admin')).to_perform_action('home')
      end
      it "does not allow action if role does not match" do
        guard.should_not authorize(account_with_role(:worker)).to_perform_action('home')
        guard.should_not authorize(account_with_role(:god)).to_perform_action('home')
      end
      it "does not allow action if person not passed" do
        guard.should_not authorize(nil).to_perform_action('home')
      end
    end

    describe "on a leveled action rule" do
      before do
        guard.leveled_rule 'some_controller#some_action', :admin
        guard.leveled_rule 'some_controller#some_other_action', :admin, :king
      end

      it "disallows action when no account available" do
        guard.should_not authorize(nil).to_perform_action('some_controller#some_action')
        guard.should_not authorize(nil).to_perform_action('some_controller#some_other')
      end

      it "allows action for that level and higher" do
        guard.should authorize(account_with_role(:god)).to_perform_action('some_controller#some_action')
        guard.should authorize(account_with_role(:admin)).to_perform_action('some_controller#some_action')
        guard.should_not authorize(account_with_role(:worker)).to_perform_action('some_controller#some_action')
      end

      it "allows action for that level and higher until second level" do
        guard.should authorize(account_with_role(:king)).to_perform_action('some_controller#some_other_action')
        guard.should authorize(account_with_role(:admin)).to_perform_action('some_controller#some_other_action')
        guard.should_not authorize(account_with_role(:god)).to_perform_action('some_controller#some_other_action')
        guard.should_not authorize(account_with_role(:worker)).to_perform_action('some_controller#some_other_action')
      end

      it "does not allow the action for a account with an illegal role value" do
        guard.should_not authorize(account_with_role(:biker)).to_perform_action('some_controller#some_action')
      end
    end

    describe "on a leveled action rule with a block" do
      let(:mock_block_body) { mock }

      before do
        guard.leveled_rule('some_controller#some_action', :admin) do |*args|
          mock_block_body.block_called(*args)
        end
      end

      it "does not authorize action if the rule disallows the action" do
        account = account_with_role(:worker)
        mock_block_body.should_receive(:block_called).never
        guard.should_not authorize(account).to_perform_action('some_controller#some_action')
      end

      it "calls block if action is authorized" do
        account = account_with_role(:admin)
        mock_block_body.should_receive(:block_called).with(account, request_params_for('some_controller#some_action'))
        guard.authorized?(account, a_request_for( 'some_controller#some_action'))
      end

      it "does not authorize action if role sufices and block returns false" do
        account = account_with_role(:admin)
        mock_block_body.stub(:block_called).and_return false
        guard.should_not be_authorized(account, a_request_for('some_controller#some_action'))
      end

      it "authorizes action is role sufices and block returns true" do
        account = account_with_role(:admin)
        mock_block_body.stub(:block_called).and_return true
        guard.should be_authorized(account, a_request_for('some_controller#some_action'))
      end
    end

    describe "matching rules" do
      before do
        guard.allow_rule('home')
        guard.refuse_rule('maintenance')
      end

      it "does not authorize if path does not match any rule" do
        guard.authorized?(nil, a_request_for('unmatched/path')).should be_false
      end

      it "matches a rule on exact path" do
        guard.should authorize(nil).to_perform_action('home')
      end

      it "matches a rule on part of a path" do
        guard.should authorize(nil).to_perform_action('home/contact')
      end

      it "preferres a longer path in matching" do
        guard.allow_rule('maintenance/things')
        guard.should_not authorize(nil).to_perform_action('maintenance#edit?id=1')
        guard.should authorize(nil).to_perform_action('maintenance/things')
      end

      it "preferres a longer path regardless off order of appearance" do
        guard.allow_rule('some_path#show')
        guard.refuse_rule('some_path')
        guard.should_not authorize(nil).to_perform_action('some_path#edit?id=1')
        guard.should authorize(nil).to_perform_action('some_path#show?1')
      end

      it "matches all rules from the beginnning of the path" do
        # /home/maintenance is evaluated by /home, not by /maintenance
        guard.should authorize(nil).to_perform_action('home/maintenance')
      end
    end
  end

  describe "load configuration" do
    it "loads rules from string" do
      guard.load_from_string %q{
        role :worker, 1
        role :admin, 0
        allow 'some_controller', :at_least => :worker
        allow 'some_controller#some_action', :at_least => :admin
        allow 'some_controller#when_role_matches_exact', :only_by => :worker
        allow 'some_controller#when_matches_exact_by_implication', :at_least => :worker, :at_most => :worker
        allow 'some_controller#when_block_returns_false' do  |account, request_params| 
          false
        end 
        allow '' # wildcard for other controllers
      }
      guard.should authorize(account_with_role(:admin)).to_perform_action('some_controller#some_action')
      guard.should_not authorize(account_with_role(:worker)).to_perform_action('some_controller#some_action')
      guard.should authorize(account_with_role(:worker)).to_perform_action('some_controller#some_other_action')
      guard.should authorize(account_with_role(:worker)).to_perform_action('some_other_controller#some_other_action')
      guard.should authorize(nil).to_perform_action('some_other_controller#some_other_action')
      guard.should_not authorize(account_with_role(:admin)).to_perform_action('some_controller#when_role_matches_exact')
      guard.should authorize(account_with_role(:worker)).to_perform_action('some_controller#when_matches_exact_by_implication')
      guard.should_not authorize(account_with_role(:admin)).to_perform_action('some_controller#when_matches_exact_by_implication')
      guard.should_not authorize(nil).to_perform_action('some_controller#when_block_returns_false')
        
    end
  end
end

