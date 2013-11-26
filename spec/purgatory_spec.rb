require 'support/active_record'
require 'support/widget'
require 'support/user'
require 'support/animal'
require 'support/item'
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

        it "should delete old pending purgatories with same soul" do
          @widget2 = Widget.create name: 'toy', price: 500
          @widget2.name = 'Big Toy'
          widget2_purgatory = @widget2.purgatory! user1
          @widget.name = 'baz'
          new_purgatory = @widget.purgatory! user1
          Purgatory.find_by_id(@purgatory.id).should be_nil
          Purgatory.find_by_id(widget2_purgatory.id).should be_present
          Purgatory.pending.count.should == 2
          Purgatory.last.requested_changes['name'].should == ['foo', 'baz'] 
        end

        it "should fail to create purgatory if matching pending Purgatory exists and fail_if_matching_soul is passed in" do
          @widget.name = 'baz'
          new_purgatory = @widget.purgatory! user1, fail_if_matching_soul: true
          new_purgatory.should be_nil
          Purgatory.find_by_id(@purgatory.id).should be_present
          Purgatory.pending.count.should == 1
        end

        it "should succeed to create purgatory if matching approved Purgatory exists and fail_if_matching_soul is passed in" do
          @purgatory.approve!
          @widget.name = 'baz'
          new_purgatory = @widget.purgatory! user1, fail_if_matching_soul: true
          new_purgatory.should be_present
          Purgatory.count.should == 2
        end
      end

      context "valid changes with attr_accessor" do
        before do
          create_object_change_purgatory_with_attr_accessor
          @item = Item.find(@item.id)
        end

        it "should not change the object" do
          @item.name.should == 'foo'
          @item.price.should == 100
        end

        it "should not save attr_accessor variable of object" do
          @item.dante.should == nil
        end

        it "should store the attr_accessor variables in the Purgatory object" do
          @purgatory.attr_accessor_fields.should == { :@dante => "inferno" }
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

      context "valid object using STI (single table inheritance)" do
        before {create_new_object_purgatory_with_sti}
    
        it "should create and return pending Purgatory object" do
          @purgatory.should be_present
          @purgatory.should_not be_approved
          @purgatory.should be_pending            
          Purgatory.pending.count.should == 1
          Purgatory.pending.first.should == @purgatory
          Purgatory.approved.count.should be_zero            
        end
        
        it "should return the soul as a new instance of the purgatoried class" do
          dog = @purgatory.soul
          dog.class.should == Dog
          dog.should be_new_record
        end
        
        it "should store the requester and requested changes" do
          @purgatory.requester.should == user1
          @purgatory.requested_changes['name'].first.should == nil
          @purgatory.requested_changes['name'].last.should == 'doggy'
        end
    
        it "should not create a dog" do
          Dog.count.should be_zero
        end
      end
    
      context "valid object with attr_accessor" do
        before do
          create_new_object_purgatory_with_attr_accessor
        end

        it "should store the attr_accessor variables in the Purgatory object" do
          @purgatory.attr_accessor_fields.should == { :@dante => "inferno" }
        end

        it "should store the requester and requested changes" do
          @purgatory.requester.should == user1
          @purgatory.requested_changes['name'].first.should == nil
          @purgatory.requested_changes['name'].last.should == 'foo'
          @purgatory.requested_changes['price'].first.should == nil
          @purgatory.requested_changes['price'].last.should == 100
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

    context "approving object change purgatory with attr_accessor" do
      before do
        create_object_change_purgatory_with_attr_accessor
          debugger
        @purgatory.approve!(user2)
        @item = Item.find(@item.id)
      end

      it "should apply the changes" do
        @item.name.should == 'bar'
        @item.price.should == 200
      end

      it "should apply changes that depend on attr_accessor instance_variable" do
        @item.original_name.should == "inferno"
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

    context "approving new object creation using STI" do
      before do
        create_new_object_purgatory_with_sti
        @purgatory.approve!(user2).should be_true
      end
      
      it "should create the new object and apply any callbacks" do
        Dog.count.should == 1
        dog = Dog.first
        dog.name.should == 'doggy'
        dog.original_name.should == 'doggy'
        dog.price.should == Dog::DEFAULT_PRICE
      end
    end

    context "approving new object creation with attr_accessor" do
      before do
        create_new_object_purgatory_with_attr_accessor
        @purgatory.approve!(user2)
      end

      it "should create the new object and apply any callbacks" do
        Item.count.should == 1
        item = Item.first
        item.name.should == 'foo'
        item.price.should == 100
      end

      it "should apply changes that depend on attr_accessor instance_variable" do
        Item.first.original_name.should == 'inferno'
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

  describe "#attr_accessor_instance_variables" do
    context "attr_accessor defined in a module/class that is an ancestor of ActiveRecord::Base" do
      before do
        @active_record_ancestor = ActiveRecord::Base.ancestors[1]
        @active_record_ancestor.instance_eval { attr_accessor :dante }
        @widget = Widget.new name: 'foo', price: 100
        @widget.dante = "inferno"
      end
      
      after do
        @active_record_ancestor.class_eval { undef :dante  }
        @active_record_ancestor.class_eval { undef :dante= }
      end

      it "should be empty" do
        @widget.attr_accessor_instance_variables.should == []
      end
    end

    context "attr_accessor defined in ActiveRecord::Base" do
      before do
        ActiveRecord::Base.instance_eval { attr_accessor :dante }
        @widget = Widget.new name: 'foo', price: 100
        @widget.dante = "inferno"
      end
      
      after do
        ActiveRecord::Base.class_eval { undef :dante  }
        ActiveRecord::Base.class_eval { undef :dante= }
      end

      it "should be empty" do
        @widget.attr_accessor_instance_variables.should == []
      end
    end

    context "attr_accessor defined in a module/class that is not an ancestor of ActiveRecord::Base" do
      context "attr_accessor defined in a module mixin" do
        before do
          klass = Class.new(Widget)
          module A; attr_accessor :dante; end
          klass.instance_eval { include A }

          @widget = klass.new name: 'foo', price: 100
          @widget.dante = "inferno"
        end
        
        it "should contain right values" do
          @widget.attr_accessor_instance_variables.should == [:@dante]
        end
      end

      context "attr_accessor defined in a superclass" do
        before do
          klass    = Class.new(Widget)
          subklass = Class.new(klass)
          subklass.instance_eval { attr_accessor :dante }

          @widget = subklass.new name: 'foo', price: 100
          @widget.dante = "inferno"
        end
        
        it "should contain right values" do
          @widget.attr_accessor_instance_variables.should == [:@dante]
        end
      end

      context "attr_accessor defined in a class" do
        before do
          klass    = Class.new(Widget)
          klass.instance_eval { attr_accessor :dante }

          @widget = klass.new name: 'foo', price: 100
          @widget.dante = "inferno"
        end
        
        it "should contain right values" do
          @widget.attr_accessor_instance_variables.should == [:@dante]
        end
      end
    end
  end
  
  private
  
  def create_object_change_purgatory
    @widget = Widget.create name: 'foo', price: 100
    @widget.name = 'bar'
    @widget.price = 200
    purgatory = @widget.purgatory! user1
    @purgatory = Purgatory.find(purgatory.id)
    @widget.reload
  end

  def create_new_object_purgatory
    widget = Widget.new name: 'foo', price: 100
    purgatory = widget.purgatory! user1
    @purgatory = Purgatory.find(purgatory.id)
  end

  def create_new_object_purgatory_with_sti
    dog = Dog.new name: 'doggy'
    purgatory = dog.purgatory! user1
    @purgatory = Purgatory.find(purgatory.id)
  end
  
  def create_object_change_purgatory_with_attr_accessor
    @item = Item.create name: 'foo', price: 100, dante: "classic"
    @item.name = 'bar'
    @item.price = 200
    @item.dante = "inferno"
    purgatory = @item.purgatory! user1
    @purgatory = Purgatory.find(purgatory.id)
    @item.reload
  end

  def create_new_object_purgatory_with_attr_accessor
    item = Item.new name: 'foo', price: 100, dante: "inferno"
    purgatory = item.purgatory! user1
    @purgatory = Purgatory.find(purgatory.id)
  end
end
