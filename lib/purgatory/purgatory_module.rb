module PurgatoryModule
  extend ActiveSupport::Concern

  module ClassMethods
    def use_purgatory
      self.has_many :purgatories, as: :soul
    end
  end

  def purgatory!(requester = nil)
    return nil if self.invalid?
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