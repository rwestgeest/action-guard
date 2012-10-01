module ActionGuard
  class ExactRoleRule
    def initialize(role)
      @allowed_role = role.to_s
    end
    def allows?(person, request_params)
      return false unless person
      return person.role.to_s == @allowed_role
    end
  end

  class LevelRule
    def initialize(allowed_level, to_allowed_level, role_leveler, &proc)
      @role_leveler = role_leveler
      @allowed_level = allowed_level
      @to_allowed_level = to_allowed_level
      @additional_rule = proc
    end

    def allows?(person, request_params)
      return false unless person
      return false unless @role_leveler.role(person.role) >= @role_leveler.role(@allowed_level)
      return false if @to_allowed_level && @role_leveler.role(@to_allowed_level) < @role_leveler.role(person.role)
      return true unless @additional_rule
      return @additional_rule.call(person, request_params)
    end
  end

  class AllowRule
    def initialize(&block)
      @additional_rule = block
    end
    def allows?(person, request_params)
      return @additional_rule.call(person, request_params) unless @additional_rule.nil?
      true
    end
  end

  class DisallowRule
    def allows?(person, request_params)
      false
    end
  end
end
