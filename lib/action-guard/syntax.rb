module ActionGuard
  class Syntax
    def initialize(action_guard)
      @guard = action_guard
    end
    def role(role_value, role_level)
      @guard.define_role(role_value, role_level)
    end
    def allow(path, options={}, &block)
      if options.has_key? :at_least
        @guard.leveled_rule(path, options[:at_least], &block)
      elsif options.has_key? :only_by
        @guard.exact_role_rule(path, options[:only_by])
      else
        @guard.allow_rule path
      end
    end
  end
end
