require 'support/active_record'
require 'support/widget'
require 'purgatory'

describe Purgatory do

  it "should create purgatory" do
    Purgatory.count.should be_zero
    w = Widget.new
    w.name = 'name'
    w.purgatory!
    Purgatory.count.should == 1
  end

end