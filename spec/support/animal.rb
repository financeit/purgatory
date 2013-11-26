require 'purgatory'

class Animal < ActiveRecord::Base
  before_create :set_original_name

  private

  def set_original_name
    self.original_name = name
  end
end

class Dog < Animal
  use_purgatory
  validates :name, presence: true

  DEFAULT_PRICE = 100

  before_create :set_price

  private

  def set_price
    self.price = DEFAULT_PRICE unless self.price
  end
end
