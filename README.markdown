# Purgatory

[![Build Status](https://secure.travis-ci.org/financeit/purgatory.png)](http://travis-ci.org/financeit/purgatory)
[![Code Climate](https://codeclimate.com/github/financeit/purgatory.png)](https://codeclimate.com/github/financeit/purgatory)

Purgatory is a Rails gem that allows you to save changes to an ActiveRecord model so that they can be applied at a later time.

## How to Use

First run the generator the create the required migration and initializer file:

    $ rails generate purgatory

Then migrate the database:

    $ rake db:migrate

By default the class of a purgatory's requester and approver is assumed to be 'User'. You can configure this in the config/initializers/purgatory file.

To enable Purgatory functionality in a class, add the following line to the class:

    use_purgatory

To put your changes to an ActiveRecord class into Purgatory, simply make your changes and then call the purgatory! method. You can pass in the requesting user as an optional parameter

    item = Item.find(10)
    item.price = 200
    purgatory = item.purgatory!(current_user) # returns the newly created purgatory or nil if the item is changes are invalid

By default, if you call purgatory! on an object then any pending purgatories whose soul is that same object will be destroyed. If you'd prefer this not to happen then you can pass fail_if_matching_soul as a parameter and this will make it so if there are pending purgatories with a matching soul then purgatory! will return nil and nothing will happen: 

    purgatory = item.purgatory!(current_user, fail_if_matching_soul: true) # Returns nil and does nothing if there is already a pending purgatory on same soul

To apply the changes, simply call the approve! method on the associated Pergatory instance. You can pass in the approving user as an optional parameter

    purgatory = item.purgatories.last
    purgatory.approve!(current_user) # returns a boolean for whether or not this succeeded

You can also put the creation of a new object into Purgatory

    item = Item.new price: 100
    purgatory = item.purgatory!

Call .purgatize.method(params) to put a method call into Purgatory. When the purgatory is approved the method will be called on the soul

    #without purgatory:
    item.increase_price(200)

    #with purgatory:
    item.purgatize(current_user).increase_price(200)

The following are some attributes of a purgatory:

    purgatory.soul # The ActiveRecord model instance whose changes are in purgatory
    purgatory.requester # The user who created the purgatory
    purgatory.created_at # The time when the purgatory was created
    purgatory.requested_changes # A hash of the proposed changes. The keys are the attribute names and the values are 2-element arrays where the 1st element is the old value and the 2nd element is the new value
    purgatory.approver # The user who approved the purgatory
    purgatory.approved_at # The time when the purgatory was approved
    purgatory.performable_method # Information about the method to call on the soul when the purgatory is approved

Here are some handy class and instance methods available to you:

    ### Class methods
    Purgatory.pending # Returns a relation of all pending purgatories
    Purgatory.approved # Returns a relation of all approved purgatories
    Purgatory.pending_with_matching_soul(soul) # Returns a relation of
    all pending purgatories with soul matching the object passed in

    ### Instance methods
    purgatory.pending? # Returns true if the purgatory is pending, false otherwise
    purgatory.approved? # Returns true if the purgatory has been approved, false otherwise
    purgatory.soul_with_changes # Returns the soul with the changes applied (not saved)

### ActiveRecord Lifecycle

  When using purgatory, the timing of the activerecord lifecycle differs a bit. Normally when you run "ActiveRecord#save", the entire lifecycle of activerecord gets triggered by default. But when you replace "save" with "purgatory!", the callbacks woould only run until after_validation. It's only after you run "approve!" when the rest of callbacks (ie. before_save, after_create) gets triggered as well.

    ## Normal lifecycle

    before_validation
    after_validation
    before_save
    around_save
    before_create
    around_create
    after_create
    after_save 

    ## Purgatory lifecycle

    # purgatory!
    before_validation
    after_validation

    # approve!
    before_validation
    after_validation
    before_save
    around_save
    before_create
    around_create
    after_create
    after_save 


### Handling Virtual Attributes

  Virtual attributes allow users store variables into active record objects temporarily without saving them into the database (usually created using attr_accessor). Because these attributes are sometimes being used even on later stages of activerecord lifecycle (i.e after_create, after_save), it's important that these virtual attributes continue to exist while using purgatory. If you're using purgatory, by default, these virtual attributes would only exist on "purgatory!" phase, and would get lost on the "approve!" phase. To make sure this doesn't happen, there are 2 ways of handling it. 

  1. Manual 
  
    use_purgatory :local_attributes => [:foo, :bar]

    When you pass a hash that contains a list of virtual attributes that you want to save, purgatory will save the values of these attributes into the purgatory table during the "purgatory!" phase, so that when "approve!" is later called, the virtual attributes will be retrieved and will continue to be available in the remaining activerecord lifecyle.

  2. Automatic 

    use_purgatory :local_attributes => :all

    By specifying all, Purgatory will programmatically determine what the virtual attributes are and save them when "purgatory!" is called, so that they will be available during "approve!".

## Updating Purgatory Version

    Whenever you update the version of purgatory you will need to:
    
    1. Run the generator to create required migrations
        $ rails generate purgatory
    2. Migrate the database
        $ rake db:migrate

## Contributing to Purgatory
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Elan Dubrofsky. See LICENSE.txt for
further details.

