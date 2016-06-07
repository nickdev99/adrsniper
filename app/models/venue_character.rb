class VenueCharacter < ActiveRecord::Base
  belongs_to :restaurant
  belongs_to :character
end
