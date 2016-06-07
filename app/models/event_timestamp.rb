class EventTimestamp < ActiveRecord::Base
  belongs_to :event
  belongs_to :restaurant
end
