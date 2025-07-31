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
          expect(@purgatory).to be_present
          expect(@purgatory).not_to be_approved
          expect(@purgatory).to be_pending
          expect(Purgatory.pending.count).to eq(1)
          expect(Purgatory.pending.first).to eq(@purgatory)
          expect(Purgatory.approved.count).to be_zero
        end
    
        it "should store the soul, requester and requested changes" do
          expect(@purgatory.soul).to eq(@widget)
          expect(@purgatory.requester).to eq(user1)
          expect(@purgatory.requested_changes['name'].first).to eq('foo')
          expect(@purgatory.requested_changes['name'].last).to eq('bar')
          expect(@purgatory.requested_changes['price'].first).to eq(100)
          expect(@purgatory.requested_changes['price'].last).to eq(200)
        end

        it "should return soul with changes if requested" do
          soul_with_changes = @purgatory.soul_with_changes
          expect(soul_with_changes.name).to eq('bar')
          expect(soul_with_changes.price).to eq(200)
        end
    
        it "should store attributes encrypted, but decrypt on access" do
          raw_value = @purgatory.read_attribute(:requested_changes)
          expect(raw_value['token']).to match([a_string_matching(/\A\{/), a_string_matching(/\A\{/)])

          processed_value = @purgatory.requested_changes
          expect(processed_value['token']).to eq(['tk_123', 'tk_456'])

          soul_with_changes = @purgatory.soul_with_changes
          expect(soul_with_changes.token).to eq('tk_456')
        end

        it "should not change the widget" do
          expect(@widget.name).to eq('foo')
          expect(@widget.price).to eq(100)
        end
    
        it "should allow the widget to access its purgatories" do
          expect(@widget.purgatories.count).to eq(1)
          expect(@widget.purgatories.first).to eq(@purgatory)
        end

        it "should delete old pending purgatories with same soul" do
          @widget2 = Widget.create name: 'toy', price: 500
          @widget2.name = 'Big Toy'
          widget2_purgatory = @widget2.purgatory! user1
          @widget.name = 'baz'
          new_purgatory = @widget.purgatory! user1
          expect(Purgatory.find_by_id(@purgatory.id)).to be_nil
          expect(Purgatory.find_by_id(widget2_purgatory.id)).to be_present
          expect(Purgatory.pending.count).to eq(2)
          expect(Purgatory.last.requested_changes['name']).to eq(['foo', 'baz'])
        end

        it "should fail to create purgatory if matching pending Purgatory exists and fail_if_matching_soul is passed in" do
          @widget.name = 'baz'
          new_purgatory = @widget.purgatory! user1, fail_if_matching_soul: true
          expect(new_purgatory).to be_nil
          expect(Purgatory.find_by_id(@purgatory.id)).to be_present
          expect(Purgatory.pending.count).to eq(1)
        end

        it "should succeed to create purgatory if matching approved Purgatory exists and fail_if_matching_soul is passed in" do
          @purgatory.approve!
          @widget.name = 'baz'
          new_purgatory = @widget.purgatory! user1, fail_if_matching_soul: true
          expect(new_purgatory).to be_present
          expect(Purgatory.count).to eq(2)
        end
      end

      context "valid changes with attr_accessor" do
        before do
          create_object_change_purgatory_with_attr_accessor
          @item = Item.find(@item.id)
        end

        it "should not change the object" do
          expect(@item.name).to eq('foo')
          expect(@item.price).to eq(100)
        end

        it "should not save attr_accessor variable of object" do
          expect(@item.dante).to eq(nil)
        end

        it "should store the attr_accessor variables in the Purgatory object" do
          expect(@purgatory.attr_accessor_fields).to eq({ :@dante => "inferno" })
        end

        it "should return item with changed attr_accessor if requested" do
          expect(@purgatory.soul_with_changes.dante).to eq('inferno')
        end
      end
    
      it "should not allow invalid changes to be put into purgatory" do
        widget = Widget.create name: 'foo'
        widget.name = ''
        expect(widget.purgatory!(user1)).to be_nil
        widget.reload
        expect(widget.name).to eq('foo')
        expect(Purgatory.count).to be_zero
      end
    end
    
    context "putting new object creation into purgatory" do
      context "valid object" do
        before {create_new_object_purgatory}
    
        it "should create and return pending Purgatory object" do
          expect(@purgatory).to be_present
          expect(@purgatory).not_to be_approved
          expect(@purgatory).to be_pending
          expect(Purgatory.pending.count).to eq(1)
          expect(Purgatory.pending.first).to eq(@purgatory)
          expect(Purgatory.approved.count).to be_zero
        end
        
        it "should return the soul as a new instance of the purgatoried class" do
          widget = @purgatory.soul
          expect(widget.class).to eq(Widget)
          expect(widget).to be_new_record
        end

        it "should store attributes encrypted, but decrypt on access" do
          raw_value = @purgatory.read_attribute(:requested_changes)
          expect(raw_value['token']).to match([nil, a_string_matching(/\A\{/)])

          processed_value = @purgatory.requested_changes
          expect(processed_value['token']).to eq([nil, 'tk_123'])

          soul_with_changes = @purgatory.soul_with_changes
          expect(soul_with_changes.token).to eq('tk_123')
        end
        
        it "should store the requester and requested changes" do
          expect(@purgatory.requester).to eq(user1)
          expect(@purgatory.requested_changes['name'].first).to eq(nil)
          expect(@purgatory.requested_changes['name'].last).to eq('foo')
          expect(@purgatory.requested_changes['price'].first).to eq(nil)
          expect(@purgatory.requested_changes['price'].last).to eq(100)
        end
    
        it "should not create a widget" do
          expect(Widget.count).to be_zero
        end
      end

      context "valid object using STI (single table inheritance)" do
        before {create_new_object_purgatory_with_sti}
    
        it "should create and return pending Purgatory object" do
          expect(@purgatory).to be_present
          expect(@purgatory).not_to be_approved
          expect(@purgatory).to be_pending
          expect(Purgatory.pending.count).to eq(1)
          expect(Purgatory.pending.first).to eq(@purgatory)
          expect(Purgatory.approved.count).to be_zero
        end
        
        it "should return the soul as a new instance of the purgatoried class" do
          dog = @purgatory.soul
          expect(dog.class).to eq(Dog)
          expect(dog).to be_new_record
        end
        
        it "should store the requester and requested changes" do
          expect(@purgatory.requester).to eq(user1)
          expect(@purgatory.requested_changes['name'].first).to eq(nil)
          expect(@purgatory.requested_changes['name'].last).to eq('doggy')
        end
    
        it "should not create a dog" do
          expect(Dog.count).to be_zero
        end
      end

      context "create STI object change purgatory" do
        before {create_object_change_purgatory_with_sti}

        it "should delete old purgatory on object if new one is created" do
          expect(Purgatory.count).to eq(1)
          @dog.name = 'fluffy'
          @dog.purgatory!(user1)
          expect(Purgatory.last.requested_changes['name'].last).to eq('fluffy')
          expect(Purgatory.count).to eq(1)
        end
      end
    
      context "valid object with attr_accessor" do
        before do
          create_new_object_purgatory_with_attr_accessor
        end

        it "should store the attr_accessor variables in the Purgatory object" do
          expect(@purgatory.attr_accessor_fields).to eq({ :@dante => "inferno" })
        end

        it "should store the requester and requested changes" do
          expect(@purgatory.requester).to eq(user1)
          expect(@purgatory.requested_changes['name'].first).to eq(nil)
          expect(@purgatory.requested_changes['name'].last).to eq('foo')
          expect(@purgatory.requested_changes['price'].first).to eq(nil)
          expect(@purgatory.requested_changes['price'].last).to eq(100)
        end
      end

      it "should not allow invalid object creation to be put into purgatory" do
        widget = Widget.new name: ''
        expect(widget.purgatory!(user1)).to be_nil
        expect(Purgatory.count).to be_zero
        expect(Widget.count).to be_zero
      end
    end
  end
  
  context :approve! do
    context "approving object change purgatory" do
      before do
        create_object_change_purgatory
        expect(@purgatory.approve!(user2)).to be true
        @widget.reload
      end
      
      it "should apply the changes" do
        expect(@widget.name).to eq('bar')
        expect(@widget.price).to eq(200)
      end
      
      it "should mark purgatory as approved and store approver" do
        expect(@purgatory.approver).to eq(user2)
        expect(@purgatory).to be_approved
        expect(@purgatory).not_to be_pending
        expect(Purgatory.pending.count).to be_zero
        expect(Purgatory.approved.count).to eq(1)
        expect(Purgatory.approved.first).to eq(@purgatory)
      end
      
      it "should fail if you try to approve again" do
        expect(@purgatory.approve!(user2)).to be false
      end
    end

    context "approving a performable method that returns false" do
      before do
        create_method_call_purgatory
        allow(@purgatory.soul).to receive(:rename).and_return(false)
      end

      it "should store the soul, requester and performable_method" do
        expect(@purgatory.soul).to eq(@widget)
        expect(@purgatory.requester).to eq(user1)
        expect(@purgatory.performable_method[:method]).to eq(:rename)
        expect(@purgatory.performable_method[:args]).to eq(['bar'])
      end

      it "should fail when performable method returns false" do
        expect(@purgatory.approve!(user2)).to be false
      end

      it "it should not be approved" do
        expect(@purgatory).to be_present
        expect(@purgatory).not_to be_approved
        expect(@purgatory).to be_pending
      end
    end

    context "approving object change purgatory with attr_accessor" do
      before do
        create_object_change_purgatory_with_attr_accessor
        @purgatory.approve!(user2)
        @item = Item.find(@item.id)
      end

      it "should apply the changes" do
        expect(@item.name).to eq('bar')
        expect(@item.price).to eq(200)
      end

      it "should apply changes that depend on attr_accessor instance_variable" do
        expect(@item.original_name).to eq("inferno")
      end
      
      it "should mark purgatory as approved and store approver" do
        expect(@purgatory.approver).to eq(user2)
        expect(@purgatory).to be_approved
        expect(@purgatory).not_to be_pending
        expect(Purgatory.pending.count).to be_zero
        expect(Purgatory.approved.count).to eq(1)
        expect(Purgatory.approved.first).to eq(@purgatory)
      end
      
      it "should fail if you try to approve again" do
        expect(@purgatory.approve!(user2)).to be false
      end
    end
    
    context "approving new object creation" do
      before do
        create_new_object_purgatory
        expect(@purgatory.approve!(user2)).to be true
      end
      
      it "should create the new object and apply any callbacks" do
        expect(Widget.count).to eq(1)
        widget = Widget.first
        expect(widget.name).to eq('foo')
        expect(widget.price).to eq(100)
        expect(widget.original_name).to eq('foo')
      end
      
      it "should mark purgatory as approved and store approver" do
        expect(@purgatory.approver).to eq(user2)
        expect(@purgatory).to be_approved
        expect(@purgatory).not_to be_pending
        expect(Purgatory.pending.count).to be_zero
        expect(Purgatory.approved.count).to eq(1)
        expect(Purgatory.approved.first).to eq(@purgatory)
      end

      it "should store the id of the newly created object so the purgatory can be accessed through the object" do
        widget = Widget.first
        expect(widget.purgatories.count).to eq(1)
        expect(widget.purgatories.first).to eq(@purgatory)
      end
      
      it "should fail if you try to approve again" do
        expect(@purgatory.approve!(user2)).to be false
      end
    end

    context "approving new object creation using STI" do
      before do
        create_new_object_purgatory_with_sti
        expect(@purgatory.approve!(user2)).to be true
      end
      
      it "should create the new object and apply any callbacks" do
        expect(Dog.count).to eq(1)
        dog = Dog.first
        expect(dog.name).to eq('doggy')
        expect(dog.original_name).to eq('doggy')
        expect(dog.price).to eq(Dog::DEFAULT_PRICE)
      end
    end

    context "approving new object creation with attr_accessor" do
      before do
        create_new_object_purgatory_with_attr_accessor
        @purgatory.approve!(user2)
      end

      it "should create the new object and apply any callbacks" do
        expect(Item.count).to eq(1)
        item = Item.first
        expect(item.name).to eq('foo')
        expect(item.price).to eq(100)
      end

      it "should apply changes that depend on attr_accessor instance_variable" do
        expect(Item.first.original_name).to eq('inferno')
      end
      
      it "should mark purgatory as approved and store approver" do
        expect(@purgatory.approver).to eq(user2)
        expect(@purgatory).to be_approved
        expect(@purgatory).not_to be_pending
        expect(Purgatory.pending.count).to be_zero
        expect(Purgatory.approved.count).to eq(1)
        expect(Purgatory.approved.first).to eq(@purgatory)
      end
      
      it "should fail if you try to approve again" do
        expect(@purgatory.approve!(user2)).to be false
      end
    end

    context "approving method call purgatory" do
      before{create_method_call_purgatory}
      it "should call the method" do
        expect(@widget.name).to eq('foo')
        @purgatory.approve!
        @widget.reload
        expect(@widget.name).to eq('bar')
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
          expect(purgatory.attr_accessor_fields).to eq({})
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
            expect(purgatory.attr_accessor_fields).to eq({ :@dante => "inferno" })
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
            expect(purgatory.attr_accessor_fields).to eq({ :@dante => "inferno" })

            obj = @klass_2.new name: 'foo', price: 100, minos: "inferno"
            purgatory = obj.purgatory! user1
            expect(purgatory.attr_accessor_fields).to eq({ :@minos => "inferno" })

            obj = @klass_3.new name: 'foo', price: 100
            purgatory = obj.purgatory! user1
            expect(purgatory.attr_accessor_fields).to eq({})
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
        expect(AttributeAccessorFields.determine_attr_accessor_fields(@obj)).to eq({})
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
          expect(AttributeAccessorFields.determine_attr_accessor_fields(@obj)).to eq({})
        end
      end

      context "local_attributes is array" do
        context "array size is 1" do
          before do
            AttributeAccessorFields.set_local_attributes_to_save(@klass,[:dante])
          end

          it "should only contain attr_accessors specified in array" do
            expect(AttributeAccessorFields.determine_attr_accessor_fields(@obj)).to eq({ :@dante => "inferno" })
          end
        end
        context "array size is more than 1" do
          before do
            AttributeAccessorFields.set_local_attributes_to_save(@klass,[:dante, :minos])
          end

          it "should only contain attr_accessors specified in array" do
            expect(AttributeAccessorFields.determine_attr_accessor_fields(@obj)).to eq({ :@dante => "inferno", :@minos => "inferno" })
          end

        end
      end
      
      context "value of local_variables is :all" do
        before do
          AttributeAccessorFields.set_local_attributes_to_save(@klass,:all)
        end

        it "should automatically determine attr_accessor values that doesnt include ones belonging to AR::Base and its ancestors, and then store these values" do
          expect(AttributeAccessorFields.determine_attr_accessor_fields(@obj)).to eq({ :@dante => "inferno", :@minos => "inferno", :@charon => "inferno" })
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
        expect(ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget)).to eq([])
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
        expect(ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget)).to eq([])
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
          expect(ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget)).to eq([:@dante])
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
          expect(ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget)).to eq([:@dante])
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
          expect(ActiveRecordDescendantAttributeAccessors.attr_accessor_instance_variables(@widget)).to eq([:@dante])
        end
      end
    end
    context :purgatize do
      context "putting method call into purgatory" do
        context "valid changes" do
          before {create_method_call_purgatory}
          
          it "should create and return pending Purgatory object" do
            expect(@purgatory).to be_present
            expect(@purgatory).not_to be_approved
            expect(@purgatory).to be_pending
            expect(Purgatory.pending.count).to eq(1)
            expect(Purgatory.pending.first).to eq(@purgatory)
            expect(Purgatory.approved.count).to be_zero
          end
      
          it "should store the soul, requester and performable_method" do
            expect(@purgatory.soul).to eq(@widget)
            expect(@purgatory.requester).to eq(user1)
            expect(@purgatory.performable_method[:method]).to eq(:rename)
            expect(@purgatory.performable_method[:args]).to eq(['bar'])
          end
          
          it "should delete old pending purgatories with same soul" do
            @widget2 = Widget.create name: 'toy', price: 500
            @widget2.name = 'Big Toy'
            widget2_purgatory = @widget2.purgatize(user1).rename('bar')
            @widget.name = 'baz'
            new_purgatory = @widget.purgatize(user1).rename('bar')
            expect(Purgatory.find_by_id(@purgatory.id)).to be_nil
            expect(Purgatory.find_by_id(widget2_purgatory.id)).to be_present
            expect(Purgatory.pending.count).to eq(2)
            expect(Purgatory.last.requested_changes['name']).to eq(['foo', 'baz'])
          end

          it "should fail to create purgatory if matching pending Purgatory exists and fail_if_matching_soul is passed in" do
            @widget.name = 'baz'
            new_purgatory = @widget.purgatize(user1, fail_if_matching_soul: true).rename('bar')
            expect(new_purgatory).to be_nil
            expect(Purgatory.find_by_id(@purgatory.id)).to be_present
            expect(Purgatory.pending.count).to eq(1)
          end

          it "should succeed to create purgatory if matching approved Purgatory exists and fail_if_matching_soul is passed in" do
            @purgatory.approve!
            @widget.name = 'baz'
            new_purgatory = @widget.purgatize(user1, fail_if_matching_soul: true).rename('bar')
            expect(new_purgatory).to be_present
            expect(Purgatory.count).to eq(2)
          end
        end
      end
    end
  end
  
  private
  
  def create_object_change_purgatory
    @widget = Widget.create name: 'foo', price: 100, token: 'tk_123'
    @widget.name = 'bar'
    @widget.price = 200
    @widget.token = 'tk_456'
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
    widget = Widget.new name: 'foo', price: 100, token: 'tk_123'
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

