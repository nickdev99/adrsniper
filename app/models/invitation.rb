class Invitation < ActiveRecord::Base
    belongs_to :user, :foreign_key => 'owner_id', :primary_key => 'owner_id'
    has_one :user, :foreign_key => 'redeemer_id', :primary_key => 'redeemer_id'
end
