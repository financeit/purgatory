module PurgatoryModule
  extend ActiveSupport::Concern

  module ClassMethods
    def use_purgatory
      self.has_many :purgatories, as: :soul
    end
  end

  def purgatory!(requester = nil, options = {})
    return nil if self.invalid?
    return nil if Purgatory.pending_with_matching_soul(self).any? && options[:fail_if_matching_soul]
    Purgatory.create soul: self, requester: requester
  end

  class Configuration
    attr_accessor :user_class_name
  end

  class << self
    def configure(&block)
      yield(configuration)
      configuration
    end

    def configuration
      @_configuration ||= Configuration.new
    end
  end
end
