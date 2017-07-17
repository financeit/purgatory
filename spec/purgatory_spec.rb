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

        it "should return soul with changes if requested" do
          soul_with_changes = @purgatory.soul_with_changes
          soul_with_changes.name.should == 'bar'
          soul_with_changes.price.should == 200
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

        it "should return item with changed attr_accessor if requested" do
          @purgatory.soul_with_changes.dante.should == 'inferno'
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

      context "create STI object change purgatory" do
        before {create_object_change_purgatory_with_sti}

        it "should delete old purgatory on object if new one is created" do
          Purgatory.count.should == 1
          @dog.name = 'fluffy'
          @dog.purgatory!(user1)
          Purgatory.last.requested_changes['name'].last.should == 'fluffy'
          Purgatory.count.should == 1
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

    context "approving a performable method" do
      before do
        create_method_call_purgatory
        @purgatory.soul.stub(:public_send).and_return(false)
      end

      it "should fail when performable method returns false" do
        @purgatory.approve!(user2).should be_false
      end

      it "it should not have approved_at/by attributes"
        @purgatory.approved?.should be_false
    end

    context "approving object change purgatory with attr_accessor" do
      before do
        create_object_change_purgatory_with_attr_accessor
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

      it "should store the id of the newly created object so the purgatory can be accessed through the object" do
        widget = Widget.first
        widget.purgatories.count.should == 1
        widget.purgatories.first.should == @purgatory 
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

    context "approving method call purgatory" do
      before{create_method_call_purgatory}
      it "should call the method" do
        @widget.name.should == 'foo'
        @purgatory.approve!
        @widget.reload
        @widget.name.should == 'bar'
      end
    end
  end

  describe "use_purgatory" do
    context "on class that has attr_accessors" do
      context "use_purgatory with no arguments" do
        before do
          @klass = create_subclass_of(Item)
          @klass.instance_eval { use_purgatory }
        end

        it "should not store attr_accessors" do
          obj = @klass.new name: 'foo', price: 100, dante: "inferno"
          purgatory = obj.purgatory! user1
          purgatory.attr_accessor_fields.should == {}
        end
      end

      context "use_purgatory with valid arguments" do
        context "use_purgatory with one active record class" do
          before do
            @klass = create_subclass_of(Item)
            @klass.instance_eval { use_purgatory :local_attributes => [:dante] }
          end

          it "should work" do
            obj = @klass.new name: 'foo', price: 100, dante: "inferno"
            purgatory = obj.purgatory! user1
            purgatory.attr_accessor_fields.should == { :@dante => "inferno" }
          end
        end

        context "use_purgatory with more than one active record class" do
          before do
            @klass = create_subclass_of(Item)
            @klass.instance_eval { use_purgatory :local_attributes => [:dante] }

            @klass_2 = create_subclass_of(Item)
            @klass_2.instance_eval { use_purgatory :local_attributes => [:minos]; attr_accessor :minos }

            @klass_3 = create_subclass_of(Item)
            @klass_3.instance_eval { use_purgatory }
          end

          it "should work" do
            obj = @klass.new name: 'foo', price: 100, dante: "inferno"
            purgatory = obj.purgatory! user1
            purgatory.attr_accessor_fields.should == { :@dante => "inferno" }

            obj = @klass_2.new name: 'foo', price: 100, minos: "inferno"
            purgatory = obj.purgatory! user1
            purgatory.attr_accessor_fields.should == { :@minos => "inferno" }

            obj = @klass_3.new name: 'foo', price: 100
            purgatory = obj.purgatory! user1
            purgatory.attr_accessor_fields.should == {}
          end
        end
      end
    end
  end

  describe "determine_attr_accessor_fields" do
    context "obj has no attr_accessors" do
      before do
        @obj = Widget.new
      end

      it "should not contain any thing" do
        AttributeAccessorFields.determine_attr_accessor_fields(@obj).should == {}
      end
    end

    context "obj has attr_accessors" do
      before do
        @klass = create_subclass_of(Widget)
        @klass.instance_eval { attr_accessor :dante, :minos, :charon }

        @obj = @klass.new

        @obj.dante = "inferno"
        @obj.minos = "inferno"
        @obj.charon = "inferno"
      end

      context "local_attributes is empty" do
        it "should not contain any attr_accessor values" do
          AttributeAccessorFields.determine_attr_accessor_fields(@obj).should == {}
        end
      end

      context "local_attributes is array" do
        context "array size is 1" do
          before do
            AttributeAccessorFields.set_local_attributes_to_save(@klass,[:dante])
          end

          it "should only contain attr_accessors specified in array" do
            AttributeAccessorFields.determine_attr_accessor_fields(@obj).should == { :@dante => "inferno" }
          end
        end
        context "array size is more than 1" do
          before do
            AttributeAccessorFields.set_local_attributes_to_save(@klass,[:dante, :minos])
          end

          it "should only contain attr_accessors specified in array" do
            AttributeAccessorFields.determine_attr_accessor_fields(@obj).should == { :@dante => "inferno", :@minos => "inferno" }
          end

        end
      end
      
      context "value of local_variables is :all" do
        before do
          AttributeAccessorFields.set_local_attributes_to_save(@klass,:all)
        end

        it "should automatically determine attr_accessor values that doesnt include ones belonging to AR::Base and its ancestors, and then store these values" do
          AttributeAccessorFields.determine_attr_accessor_fields(@obj).should == { :@dante => "inferno", :@minos => "inferno", :@charon => "inferno" }
        end
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

      it "should not include instance_variables that belong to ancestor of ActiveRecord::Base" do
        ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget).should == []
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

      it "should not include instance_variables that belong to ActiveRecord::Base" do
        ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget).should == []
      end
    end

    context "attr_accessor defined in a module/class that is not an ancestor of ActiveRecord::Base" do
      context "attr_accessor defined in a module mixin" do
        before do
          klass = create_subclass_of(Widget)
          module A; attr_accessor :dante; end
          klass.instance_eval { include A }

          @widget = klass.new name: 'foo', price: 100
          @widget.dante = "inferno"
        end
        
        it "should include instance_variables from attr_accessors that belong to descendant of ActiveRecord::Base" do
          ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget).should == [:@dante]
        end
      end

      context "attr_accessor defined in a superclass" do
        before do
          klass = create_subclass_of(Widget)
          subklass = create_subclass_of(klass)

          klass.instance_eval { attr_accessor :dante }

          @widget = subklass.new name: 'foo', price: 100
          @widget.dante = "inferno"
        end
        
        it "should include instance_variables from attr_accessors that belong to descendant of ActiveRecord::Base" do
          ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget).should == [:@dante]
        end
      end

      context "attr_accessor defined in a class" do
        before do
          klass    = create_subclass_of(Widget)
          klass.instance_eval { attr_accessor :dante }

          @widget = klass.new name: 'foo', price: 100
          @widget.dante = "inferno"
        end
        
        it "should include instance_variables from attr_accessors that belong to descendant of ActiveRecord::Base" do
          ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget).should == [:@dante]
        end
      end
    end
    context :purgatize do
      context "putting method call into purgatory" do
        context "valid changes" do
          before {create_method_call_purgatory}
          
          it "should create and return pending Purgatory object" do
            @purgatory.should be_present
            @purgatory.should_not be_approved
            @purgatory.should be_pending            
            Purgatory.pending.count.should == 1
            Purgatory.pending.first.should == @purgatory
            Purgatory.approved.count.should be_zero            
          end
      
          it "should store the soul, requester and performable_method" do
            @purgatory.soul.should == @widget
            @purgatory.requester.should == user1
            @purgatory.performable_method[:method].should == :rename
            @purgatory.performable_method[:args].should == ['bar']
          end
          
          it "should delete old pending purgatories with same soul" do
            @widget2 = Widget.create name: 'toy', price: 500
            @widget2.name = 'Big Toy'
            widget2_purgatory = @widget2.purgatize(user1).rename('bar')
            @widget.name = 'baz'
            new_purgatory = @widget.purgatize(user1).rename('bar')
            Purgatory.find_by_id(@purgatory.id).should be_nil
            Purgatory.find_by_id(widget2_purgatory.id).should be_present
            Purgatory.pending.count.should == 2
            Purgatory.last.requested_changes['name'].should == ['foo', 'baz'] 
          end

          it "should fail to create purgatory if matching pending Purgatory exists and fail_if_matching_soul is passed in" do
            @widget.name = 'baz'
            new_purgatory = @widget.purgatize(user1, fail_if_matching_soul: true).rename('bar')
            new_purgatory.should be_nil
            Purgatory.find_by_id(@purgatory.id).should be_present
            Purgatory.pending.count.should == 1
          end

          it "should succeed to create purgatory if matching approved Purgatory exists and fail_if_matching_soul is passed in" do
            @purgatory.approve!
            @widget.name = 'baz'
            new_purgatory = @widget.purgatize(user1, fail_if_matching_soul: true).rename('bar')
            new_purgatory.should be_present
            Purgatory.count.should == 2
          end
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

  def create_method_call_purgatory
    @widget = Widget.create name: 'foo', price: 100
    purgatory = @widget.purgatize(user1).rename('bar')
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

  def create_object_change_purgatory_with_sti
    @dog = Dog.create name: 'doggy'
    @dog.name = 'codey'
    purgatory = @dog.purgatory! user1
    @purgatory = Purgatory.find(purgatory.id)
    @dog.reload
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

  def create_subclass_of(klass)
    Class.new(klass)  
  end
end
