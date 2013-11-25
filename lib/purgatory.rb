require 'purgatory/purgatory_module'
ActiveRecord::Base.send(:include, PurgatoryModule)
