require 'purgatory'

class Address < ActiveRecord::Base
  belongs_to :widget
end
