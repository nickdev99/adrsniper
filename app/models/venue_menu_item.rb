class VenueMenuItem < ActiveRecord::Base
  belongs_to :restaurant
  belongs_to :search_time
  belongs_to :event
  belongs_to :menu_item
end
