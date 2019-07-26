# frozen_string_literal: true

module SwitchConnection
  class Error < StandardError
  end

  class ReadonlyError < Error
  end

  class UnconfiguredError < Error
  end
end
