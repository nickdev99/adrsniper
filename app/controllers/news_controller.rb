require 'unirest'
require 'htmlentities'

class NewsController < ApplicationController
    def read_post
        r = Unirest.get "https://wdwtools.com/blog/wp-json/posts?filter[name]=#{params[:slug]}"
        @post_response = r.body[0]
        @post_title = HTMLEntities.new.decode @post_response["title"]["rendered"]
        @post_content = HTMLEntities.new.decode @post_response["content"]["rendered"]
        @post_time = (Chronic.parse(@post_response["date_gmt"])).strftime("%B %-d, %Y")
        ur = Unirest.get "https://wdwtools.com/blog/wp-json/wp/users/#{@post_response["author"]}", auth: {:user=>"admin", :password=>"O9yEPpeVhcDX"}
        @user_response = ur.body
        @user_name = @user_response["name"]
    end

    def index
        r = Unirest.get "https://wdwtools.com/blog/wp-json/posts?filter[posts_per_page]=20"
        @news = []
        r.body.each do |p|
            @news << {:post_id => p["id"], :slug => p["slug"], :image => p["featured_image"], :title => HTMLEntities.new.decode(p["title"]["rendered"])}
        end
    end
end
