class VenueMenuNote < ActiveRecord::Base
  belongs_to :restaurant
  belongs_to :search_time
  belongs_to :event
end
