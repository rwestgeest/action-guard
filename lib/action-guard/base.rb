module ActionGuard
  class Guard
    def initialize
      @rules = {}
      @rules.default = DisallowRule.new
      @roles = {}
      @roles.default = Role.new(:illegal_role, 100000)
    end

    def load_from_string(configuration, name = nil)
      Syntax.new(self).instance_eval(configuration, name || 'unknown')
    end

    def define_role(role, level)
      @roles[role.to_sym] = Role.new(role, level)
    end

    def role(role_value)
      @roles[role_value.to_sym]
    end

    def valid_role?(role)
      @roles.has_key?(role.to_sym)
    end

    def valid_roles
      @roles.keys.map { |r| r.to_s }
    end

    def leveled_rule(path_matcher, from_role_value, to_role_value = nil, &block)
      raise Error.new("undefined role '#{from_role_value}'") unless valid_role?(from_role_value)
      raise Error.new("undefined role '#{to_role_value}'") if to_role_value && !valid_role?(to_role_value)
      rules[path_matcher] = LevelRule.new(from_role_value, to_role_value, self, &block)
    end

    def allow_rule(path_matcher, &block)
      rules[path_matcher] = AllowRule.new(&block)
    end

    def refuse_rule(path_matcher)
      rules[path_matcher] = DisallowRule.new
    end

    def exact_role_rule(path_matcher, role_value)
      rules[path_matcher] = ExactRoleRule.new(role_value)
    end

    def authorized?(person, request_params)
      raise Error.new("no configuration loaded") if rules.empty?
      path = "#{request_params['controller']}##{request_params['action']}"
      rule_key = rules.keys.sort{|x,y| y <=> x }.select {|k| path =~ /^#{k}/}.first
      rules[rule_key].allows?(person,request_params)
    end

    private
    attr_reader :rules
  end
end
