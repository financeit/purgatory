require 'support/active_record'
require 'support/widget'
require 'support/user'
require 'purgatory/purgatory'

describe Purgatory do
  let(:user1) {User.create name: 'Elan'}
  let(:user2) {User.create name: 'Reg'}
  context :purgatory! do
    context "putting object changes into purgatory" do
      context "valid changes" do
        before {create_object_change_purgatory}
        
        it "should create and return pending Purgatory object" do
          @purgatory.should be_present
          @purgatory.should_not be_approved
          @purgatory.should be_pending            
          Purgatory.pending.count.should == 1
          Purgatory.pending.first.should == @purgatory
          Purgatory.approved.count.should be_zero            
        end
    
        it "should store the soul, requester and requested changes" do
          @purgatory.soul.should == @widget
          @purgatory.requester.should == user1
          @purgatory.requested_changes['name'].first.should == 'foo'
          @purgatory.requested_changes['name'].last.should == 'bar'
          @purgatory.requested_changes['price'].first.should == 100
          @purgatory.requested_changes['price'].last.should == 200
        end
    
        it "should not change the widget" do
          @widget.name.should == 'foo'
          @widget.price.should == 100
        end
    
        it "should allow the widget to access its purgatories" do
          @widget.purgatories.count.should == 1
          @widget.purgatories.first.should == @purgatory
        end
      end
    
      it "should not allow invalid changes to be put into purgatory" do
        widget = Widget.create name: 'foo'
        widget.name = ''
        widget.purgatory!(user1).should be_nil      
        widget.reload
        widget.name.should == 'foo'
        Purgatory.count.should be_zero
      end
    end
    
    context "putting new object creation into purgatory" do
      context "valid object" do
        before {create_new_object_purgatory}
    
        it "should create and return pending Purgatory object" do
          @purgatory.should be_present
          @purgatory.should_not be_approved
          @purgatory.should be_pending            
          Purgatory.pending.count.should == 1
          Purgatory.pending.first.should == @purgatory
          Purgatory.approved.count.should be_zero            
        end
        
        it "should return the soul as a new instance of the purgatoried class" do
          widget = @purgatory.soul
          widget.class.should == Widget
          widget.should be_new_record
        end
        
        it "should store the requester and requested changes" do
          @purgatory.requester.should == user1
          @purgatory.requested_changes['name'].first.should == nil
          @purgatory.requested_changes['name'].last.should == 'foo'
          @purgatory.requested_changes['price'].first.should == nil
          @purgatory.requested_changes['price'].last.should == 100
        end
    
        it "should not create a widget" do
          Widget.count.should be_zero
        end
      end
    
      it "should not allow invalid object creation to be put into purgatory" do
        widget = Widget.new name: ''
        widget.purgatory!(user1).should be_nil      
        Purgatory.count.should be_zero
        Widget.count.should be_zero
      end
    end
  end
  
  context :approve! do
    context "approving object change purgatory" do
      before do
        create_object_change_purgatory
        @purgatory.approve!(user2).should be_true
        @widget.reload
      end
      
      it "should apply the changes" do
        @widget.name.should == 'bar'
        @widget.price.should == 200
      end
      
      it "should mark purgatory as approved and store approver" do
        @purgatory.approver.should == user2
        @purgatory.should be_approved
        @purgatory.should_not be_pending            
        Purgatory.pending.count.should be_zero
        Purgatory.approved.count.should == 1
        Purgatory.approved.first.should == @purgatory
      end
      
      it "should fail if you try to approve again" do
        @purgatory.approve!(user2).should be_false
      end
    end
    
    context "approving new object creation" do
      before do
        create_new_object_purgatory
        @purgatory.approve!(user2).should be_true
      end
      
      it "should create the new object and apply any callbacks" do
        Widget.count.should == 1
        widget = Widget.first
        widget.name.should == 'foo'
        widget.price.should == 100
        widget.original_name.should == 'foo'
      end
      
      it "should mark purgatory as approved and store approver" do
        @purgatory.approver.should == user2
        @purgatory.should be_approved
        @purgatory.should_not be_pending            
        Purgatory.pending.count.should be_zero
        Purgatory.approved.count.should == 1
        Purgatory.approved.first.should == @purgatory
      end
      
      it "should fail if you try to approve again" do
        @purgatory.approve!(user2).should be_false
      end
    end
  end
  
  private
  
  def create_object_change_purgatory
    @widget = Widget.create name: 'foo', price: 100
    @widget.name = 'bar'
    @widget.price = 200
    @purgatory = @widget.purgatory! user1
    @widget.reload
    @purgatory.reload
  end
  
  def create_new_object_purgatory
    widget = Widget.new name: 'foo', price: 100
    @purgatory = widget.purgatory! user1
    @purgatory.reload
  end
end
