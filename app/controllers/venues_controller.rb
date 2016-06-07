require 'chronic'
require 'json'
require 'msgpack'
require 'redis'

class VenuesController < ApplicationController
    autocomplete :restaurant, :name

    def show_info
        restaurant = Restaurant.find_by_slug params[:slug]
        @venue_meta = VenuesMeta.find_by_restaurant_id restaurant.id
        @dine_name = restaurant.name
        @dine_description = HTMLEntities.new.decode get_from_wp("id", @venue_meta.wordpress_content_id)["content"]["rendered"]
    end

    def fire_search(date, meal_time, party_size)
        puts "Requested search result not found in cache, obtaining ..."
        conf = {}
        conf["searchStartDate"] = date
        conf["searchEndDate"] = date
        conf["searchTime"] = meal_time
        conf["skipPricing"] = false
        conf["type"] = "dining"
        conf["partySize"] = party_size
        conf["id"] = "000000000;entityType=NULL"
        conf["restaurantMainUrl"] = "https://google.com"
        conf["humanName"] = "NO RESTAURANT"

        fn = "/tmp/#{(0...8).map { (65 + rand(26)).chr }.join}"
        File.open(fn, 'w') { |f| f.write(JSON.dump(conf)) }
        puts "Wrote temporary config file to #{fn} ..."
        puts "Forking now ..."

        pid = Process.spawn "python /home/jeff/adrsniper/adrsniper/dis-mass/scrape.py #{fn}"
        while Process.wait(pid, Process::WNOHANG).nil?
            sleep(0.005)
        end

        File.unlink fn
    end

    def combine_hash(ha, hb)
        puts "ha is #{ha.inspect}"
        puts "hb is #{hb.inspect}"
        if ha.nil? and !hb.nil?
            return hb
        elsif !ha.nil? and hb.nil?
            return ha
        elsif ha.nil? and hb.nil?
            return {}
        end
        nh = hb.merge(ha)
        ha.each do |ak, av|
            if hb.has_key? ak
                hbn = hb[ak]
                han = ha[ak]
                if nh[ak].nil?
                    nh[ak] = {}
                else
                end
                nhn = nh[ak]
                if hbn.respond_to? :has_key? 
                    hbn.each do |bk, bv|
                        if bv.respond_to? :has_key?
                            nhn[bk] = combine_hash(han[bk], hbn[bk])
                        else
                            nhn[bk] = bv
                        end
                    end
                end
            end
        end
        return nh
    end

    def old_combine_hash(hash_a, hash_b)
        new_h = hash_b.merge(hash_a)
        hash_a.each do |ak, av|
            if !hash_b[ak].nil?
                hash_b[ak].each do |bk, bv|
                    if hash_a[ak][bk].nil?
                        new_h[ak][bk] = bv
                    end
                end
            end
        end
        return new_h
    end

    def dine_search
        #dc = Dalli::Client.new('127.0.0.1', {:compress => false, :serializer => JSON, :raw => true})
        #dc = Dalli::Client.new('127.0.0.1', {:serializer => MessagePack, :compress => false})
        redis = Redis.new

        date_range_start = params[:date_range_start]
        date_range_end = params[:date_range_end]
        party_size = params[:party_size]
        meal_time = params[:meal_time]
        specific_restaurant = params[:lookup_id]
        area = params[:area]
        if area.present?
          puts "Area is present: #{area}"
          @area_id = Area.find_by_name(area).id
        else
          puts "Area not present."
        end

        if !date_range_start.nil? && !date_range_end.nil? && !party_size.nil? && !meal_time.nil?
          if request.format.symbol == :json
            if meal_time == "Breakfast"
              searchTime = "80000712"
            elsif meal_time == "Brunch"
              searchTime = "80000713"
            elsif meal_time == "Lunch"
              searchTime = "80000717"
            elsif meal_time == "Dinner"
              searchTime = "80000714"
            end

            @search_time_id = SearchTime.find_by_name(meal_time).id

            start_date = Chronic.parse(date_range_start)
            final_date = Chronic.parse(date_range_end)
            entityTypeURLMap = {
                'restaurant' => 'table-service',
                'Dining-Event' => 'dining-event',
                'Dinner-Show' => 'dinner-show',
            }
            link_base = "https://disneyworld.disney.go.com/dining-reservation/book-"
            links = {}
            threads = []
            procd_dates = []
            date_list = (start_date.to_date().upto(final_date.to_date())).to_a
            if date_list.length > 10
              render "I'm sorry Dave, I'm afraid I can't do that. You have too many days."
            end

            if Rails.configuration.adrsniper.fake_results
              search_links_f = File.open(Rails.root.join("sample_#{meal_time.downcase}_search_results.json").to_s, 'r')
              search_links_master = JSON.parse(search_links_f.read())
              search_links_f.close()
            end

            if search_links_master.nil?
              search_links_master = {}
            end

            puts "DATE LIST LENGTH: #{date_list.length} SEE HERE"
            date_list.each do |d|

              threads << Thread.new {
                formatted_date = d.strftime("%Y-%m-%d")
                search_key = "mr_#{formatted_date},#{searchTime},#{party_size}"
                search_key_links = "#{search_key}-processed_links"
                if Rails.configuration.adrsniper.fake_results
                  search_links = search_links_master[search_key_links]
                else
                  search_links = redis.get(search_key_links)
                  search_links = JSON.parse search_links
                end
                iteration_links = {}
                if search_links.nil?
                  if Rails.configuration.adrsniper.fake_results
                    Thread.exit
                  end
                  search_res = redis.get(search_key)
                  count = 1
                  while search_res.nil?
                    if count > 5
                      render "Woops, something bad happened. Please try again later."
                    end
                    fire_search(formatted_date, meal_time, party_size)
                    search_res = redis.get(search_key)
                    count += 1
                  end

                  search_json = JSON.parse(search_res)['availability']
                  if search_json.nil?
                    puts "Can't read this one!"
                    puts search_res.inspect
                    puts "Skipping it."
                    next
                  end
                  search_json.each do |k, v|
                    #skip if no offers
                    if v['availableTimes'][0]['offers'].nil?
                      next
                    end

                    #skip if specific restaurant selected and this is not it
                    if !specific_restaurant.nil? and k != specific_restaurant
                      next
                    end

                    begin
                      venue = Venue.lookup(k)
                      venue_id = venue.id
                    rescue
                      puts "no id attribute on this venues, skipping."
                      puts "DYING WITH KEY #{k}"
                      next
                    end

                    if iteration_links[k].nil?
                      iteration_links[k] = {}
                    end

                    entityType = k.split("entityType=")[1]
                    v['availableTimes'].each do |avt|
                      if avt['offers'].nil?
                        next
                      end
                      #set host venues id if this is an event
                      if !avt['id'].nil?
                        host_id = avt['id']
                      else
                        host_id = k
                      end

                      avt['offers'].each do |off|
                        off_datetime = Chronic.parse off["dateTime"]
                        off_date = off_datetime.strftime("%Y-%m-%d")

                        if iteration_links[k][host_id].nil?
                          iteration_links[k][host_id] = {}
                        end

                        if iteration_links[k][host_id][off_date].nil?
                          iteration_links[k][host_id][off_date] = {}
                        end

                        if iteration_links[k][host_id][off_date][off["dateTime"]].nil?
                          iteration_links[k][host_id][off_date][off["dateTime"]] = {}
                          iteration_links[k][host_id][off_date][off["dateTime"]]["booking_url"] = "#{link_base}#{entityTypeURLMap[entityType]}/?"
                        end

                        iteration_links[k][host_id][off_date][off["dateTime"]]["booking_url"] += "offerId[]=#{off["url"]}&"
                      end
                    end
                  end
                  redis.set(search_key_links, JSON.dump(iteration_links))
                  redis.expire(search_key_links, 3000)
                  procd_dates << iteration_links
                  if Rails.configuration.adrsniper.gather_results = true
                    search_links_master[search_key_links] = iteration_links
                  end
                else
                  puts "Processed links found in cache, using those."
                  procd_dates << search_links
                end
              }
            end

            done_threads = []
            puts "Waiting for threads to finish ..."
            while threads.length > 0
              threads.each_with_index do |thr, i|
                if thr.alive?
                  thr.join(0.15)
                else
                  done_threads << thr
                  threads.delete(thr)
                end
              end
            end

            if Rails.configuration.adrsniper.gather_results
              f = File.open("#{(Rails.root.join(Time.now.to_i.to_s)).to_s}-master.json", 'w')
              f.write(JSON.dump(search_links_master))
              f.close
            end

            procd_dates.each do |link|
              if link.nil?
                puts "link is nil, skipping."
                next
              elsif links.nil?
                links = {}
              end
              links = combine_hash(link, links)
            end
            @links = links
            puts "~~~~\n~~~~\n~~~~\n~~~~"
            #puts @links.inspect
            #puts "Links is #{@links.length.inspect} units long."
            html = render_to_string(:template => 'venues/dine_data.html.erb', :layout => false, :locals => { :links => @links, :area_id => @area_id, :search_time_id => @search_time_id })

            render :plain => html
          end
        end
    end
end