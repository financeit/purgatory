# Purgatory

Purgatory allows you to put changes to an ActiveRecord model into purgatory until they are approved

## How to Use

First run the generator the create the required migrations:

    $ rails generate purgatory

Then migrate the database:

    $ rake db:migrate

To enable Purgatory functionality in a class, add the following line to the class:

    use_purgatory

To put your changes to an ActiveRecord class into Purgatory, simply make your changes and then call the purgatory! method, passing the requesting user as a parameter

    item = Item.find(10)
    item.price = 200
    item.purgatory!(current_user)

To apply the changes, simply call the approve! method on the associated Pergatory instance, passing in the approving user as a parameter

    purgatory = Purgatory.where(soul_id: 10, soul_type: 'Item')
    purgatory.approve!(current_user)

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

