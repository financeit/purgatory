# Purgatory

Purgatory allows you to put changes to an ActiveRecord model into purgatory until they are approved

## How to Use

First run the generator the create the required migrations:

    $ rails generate purgatory

Then migrate the database:

    $ rake db:migrate

To enable Purgatory functionality in a class, add the following line to the class:

    use_purgatory

To put your changes to an ActiveRecord class into Purgatory, simply make your changes and then call the purgatory! method. You can pass in the requesting user as an optional parameter

    item = Item.find(10)
    item.price = 200
    purgatory = item.purgatory!(current_user) # returns the newly created purgatory or nil if the item is changes are invalid

To apply the changes, simply call the approve! method on the associated Pergatory instance. You can pass in the approving user as an optional parameter

    purgatory = item.purgatories.last
    purgatory.approve!(current_user) # returns a boolean for whether or not this succeeded

You can also put the creation of a new object into Purgatory

    item = Item.new price: 100
    purgatory = item.purgatory!

The following are some attributes of a purgatory:

    purgatory.soul # The ActiveRecord model instance whose changes are in purgatory
    purgatory.requester # The user who created the purgatory
    purgatory.created_at # The time when the purgatory was created
    purgatory.requested_changes # A hash of the proposed changes. The keys are the attribute names and the values are 2-element arrays where the 1st element is the old value and the 2nd element is the new value
    purgatory.approver # The user who approved the purgatory
    purgatory.approved_at # The time when the purgatory was approved

Here are some handy scopes and methods available to you:

    ### Scopes
    Purgatory.pending # Returns a relation of all pending purgatories
    Purgatory.approved # Returns a relation of all approved purgatories

    ### Methods
    purgatory.pending? # Returns true if the purgatory is pending, false otherwise
    purgatory.approved? # Returns true if the purgatory has been approved, false otherwise

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

