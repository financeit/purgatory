require 'purgatory'

class Item < ActiveRecord::Base
  use_purgatory local_attributes: [:dante]

  validates :name, presence: true

  attr_accessor :dante

  after_save :set_original_name
  
  private
  
  def set_original_name
    update_column(:original_name, @dante)
  end
end
