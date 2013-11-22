module PurgatoryModule
  extend ActiveSupport::Concern

  module ClassMethods
    def use_purgatory
      self.has_many :purgatories, as: :soul
    end
  end

  def purgatory!(requester)
    return nil if self.invalid?
    Purgatory.create soul: self, requester: requester
  end
end