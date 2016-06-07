class Venue
    def self.lookup(lookup_id_in)
        lookup_id = lookup_id_in.strip
        venue = nil
        venue = Restaurant.find_by_lookup_id lookup_id
        if venue.nil?
            venue = Event.find_by_lookup_id lookup_id
        end
        if venue.nil?
            puts "We don't know about this venues: #{lookup_id}"
        end
        return venue
    end
end
