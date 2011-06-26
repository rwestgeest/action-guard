module ActionGuard
  class Role
    attr_reader :level
    def initialize(value, level)
      @value = value
      @level = level
    end

    def >=(other)
      level <= other.level
    end

    def to_s
      "Role(:#{@value})"
    end
  end
end
