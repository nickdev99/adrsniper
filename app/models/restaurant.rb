class Restaurant < ActiveRecord::Base
    has_many :watches
    has_many :venues_meta, :class_name => VenuesMeta
    belongs_to :area
end
