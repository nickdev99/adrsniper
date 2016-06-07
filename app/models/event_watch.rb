class EventWatch < ActiveRecord::Base
  belongs_to :event
  belongs_to :user
  belongs_to :event_timestamp
  belongs_to :watch_config
end
