module ActionGuard
  class ExactRoleRule
    def initialize(role)
      @allowed_role = role.to_s
    end
    def allows?(person)
      return false unless person
      return person.role.to_s == @allowed_role
    end
  end

  class LevelRule
    def initialize(allowed_level, role_leveler, &proc)
      @role_leveler = role_leveler
      @allowed_level = allowed_level
      @additional_rule = proc
    end

    def allows?(person)
      return false unless person
      return false unless @role_leveler.role(person.role) >= @role_leveler.role(@allowed_level)
      return true unless @additional_rule
      return @additional_rule.call(person)
    end
  end

  class AllowRule
    def allows?(person)
      true
    end
  end

  class DisallowRule
    def allows?(person)
      false
    end
  end
end
