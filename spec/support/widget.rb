require 'purgatory'

class Widget < ActiveRecord::Base
  use_purgatory
  validates :name, presence: true
end