require 'purgatory'

class Widget < ActiveRecord::Base
  use_purgatory nested_attributes: [:address]
  validates :name, presence: true
  before_create :set_original_name
  has_one :address
  
  def rename(new_name)
    self.update_attributes(name: new_name)
  end

  private
  
  def set_original_name
    self.original_name = name
  end
end
