class EventCrawl < ActiveRecord::Base
  belongs_to :event
  belongs_to :event_watch
  belongs_to :watch_config
end
