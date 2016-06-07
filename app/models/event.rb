class Event < ActiveRecord::Base
    has_many :venues_meta, class_name: VenuesMeta
    has_one :area
end
