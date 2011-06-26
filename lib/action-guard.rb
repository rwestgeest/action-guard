require 'action-guard/syntax'
require 'action-guard/rules'
require 'action-guard/role'
require 'action-guard/base'

module ActionGuard
  class Error < StandardError; end

  def self.flush
    @action_guard = ActionGuard::Guard.new
  end

  def self.load_from_file(file_path)
    raise "authorization file #{file_path} not found" unless File.file?(file_path)
    @action_guard = ActionGuard::Guard.new
    @action_guard.load_from_string(File.read(file_path), file_path)
  end

  def self.authorized?(person, path)
    @action_guard.authorized?(person, path) 
  end

  def self.valid_roles
    @action_guard.valid_roles
  end
end
