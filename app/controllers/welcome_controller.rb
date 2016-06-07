require 'unirest'
require 'htmlentities'

class WelcomeController < ApplicationController
    def index
        @news = []
        r = Unirest.get "https://wdwtools.com/blog/wp-json/posts?filter[posts_per_page]=6"
        r.body.each do |p|
            puts p
            @news << {:post_id => p["id"], :slug => p["slug"], :image => p["featured_image"], :title => HTMLEntities.new.decode(p["title"]["rendered"])}
        end
        puts @news
    end

    def testimonials
    end
end
