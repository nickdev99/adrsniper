require 'digest/md5'
require 'chronic'
require 'active_support/core_ext/numeric/time'

class WatchesController < ApplicationController
    before_action :authenticate_user!
    #before_action { |c| c.validate_product_ownership!([4,3,2]) }

    def get_passthru_prod_id
        if @passthru_prod_id.nil?
            @passthru_prod_id = Products.where("name == 'Watched Reservation'")[0].id
        end
    end

    def watch_paid?(watch_id)
        get_passthru_prod_id
        up = UserProducts.where("passthru_id == ? AND product_id == ?", watch_id, @passthru_prod_id)
        if up.present?
            return true
        else
            return false
        end
    end

    def create
        @user = User.find(current_user.id)
        @watch = Watch.new(watch_params)
        @watch.user_id = current_user.id
        @max_watched_days = Watch.get_max_watched_days(current_user.id)

        cfg_raw = @watch.build_scraper_config()
        cfg_hash = Digest::MD5.hexdigest(cfg_raw)
        @watch.cfg_hash = cfg_hash

        puts WatchConfig.exists? :cfg_hash => cfg_hash
        if !WatchConfig.exists? :cfg_hash => cfg_hash then
            @watchcfg = WatchConfig.new()
            @watchcfg.cfg_raw = cfg_raw
            @watchcfg.cfg_hash = cfg_hash
            @watchcfg.save
       end

        @watch.notify_prefs = process_notify_ranges(params)

        # watches are automatically paid if user is elite.
        if @user.has_elite or (@user.subscription_thru.present? and @user.subscription_thru > Time.now)
            @watch.paid = true
        else
            @watch.paid = false
        end

        @watch.save

        if !@watch.errors.empty?
            render :action => 'edit'
        else
            redirect_to watches_path
        end
    end

    def new
        @watch = Watch.new
        @event_watch = EventWatch.new
        @user = User.find(current_user.id)
        @max_watched_days = Watch.get_max_watched_days(current_user.id)

        if @user.has_elite or (@user.subscription_thru.present? and @user.subscription_thru > Time.now)
            @sticky = false
        else
            @sticky = true
        end
    end

    def index
        @watches = Watch.where(user_id: current_user.id)
        @user = User.find(current_user.id)
        @max_watched_days = Watch.get_max_watched_days(current_user.id)
    end

    def show
        @watch = Watch.unscoped.find(params[:id])

        # verify ownership
        return if kickout(current_user.id, @watch.user_id)

        # this is a dirty hack while we wait to figure out why the assoc
        # isn't working. It might be slow. #FIXME.
        @watchcfg = WatchConfig.find_by(:cfg_hash => @watch.cfg_hash)
    end

    def destroy
        @watch = Watch.unscoped.find(params[:id])
        @user = User.find(current_user.id)

        return if kickout(@user.id, @watch.user_id)

        @watch.enabled = false
        @watch.save(validate: false)

        redirect_to watches_path
    end

    def update
        @watch = Watch.unscoped.find(params[:id])
        @user = User.find(current_user.id)
        @max_watched_days = Watch.get_max_watched_days(current_user.id)

        # verify ownership
        return if kickout(@user.id, @watch.user_id)

        if @user.has_elite or (@user.subscription_thru.present? and @user.subscription_thru > Time.now) or @watch.paid == false
            prm = watch_params()
        else
            # only allow changes to party size if user does not have elite
            prm = watch_params_sticky()
        end

        prm[:notify_prefs] = process_notify_ranges(params)

        if @watch.update(prm)
            puts "Updated."
            redirect_to watches_path
        else
            render 'edit'
        end
    end

    def edit
        @watch = Watch.unscoped.find(params[:id])
        @user = User.find(current_user.id)
        @max_watched_days = Watch.get_max_watched_days(current_user.id)

        if @user.has_elite or (@user.subscription_thru.present? and @user.subscription_thru > Time.now) or @watch.paid == false
            @sticky = false
        else
            @sticky = true
        end

        # verify ownership
        return if kickout(@user.id, @watch.user_id)
    end

    def kickout(a, b)
        if a != b
            flash[:error] = "You don't own that watch. This event has been logged."
            redirect_to watches_path
            return true
        end
        return false
    end

    def show_event_timestamps
        Time.zone = "America/New_York"
        Chronic.time_class = Time.zone

        search_start_date = Chronic.parse(params[:search_start_date])
        search_end_date = Chronic.parse(params[:search_end_date])
        event_id = params[:event_id]
        ets = EventTimestamp.where("start_timestamp BETWEEN ? AND ? AND event_id = ?", search_start_date.to_date.to_s, search_end_date.to_date.to_s, event_id)
        puts "ETSSTETESTSETSETSETSETSETSETSET"
        puts "ETSSTETESTSETSETSETSETSETSETSET"
        puts "ETSSTETESTSETSETSETSETSETSETSET"
        puts ets
        puts "ETSSTETESTSETSETSETSETSETSETSET"
        puts "ETSSTETESTSETSETSETSETSETSETSET"
        render :json => ets
    end

    private
    def out_of_range(d)
        if (d - Date.today).to_i.abs > 180
            return true
        else
            return false
        end
    end

    def process_notify_ranges(params, jsonify = true)
        require 'active_support/core_ext/numeric/time'

        Time.zone = "America/New_York"
        Chronic.time_class = Time.zone

        notify_prefs = []
        submitted_ranges = []

        params.each do |parm_name, parm_val|
            puts parm_name
            # somewhat dangerous here -- an unrelated thing may eventually contain
            # "date_dropdown" in its name. We shouldn't do it this way, but it's
            # easier right now to do so and I'm lazy. #FIXME
            if parm_name.include?("date_dropdown")
                range_id = /date_notify_range_(\d+)_/.match(parm_name)[1]
                submitted_ranges << range_id
            end
        end

        submitted_ranges.each do |rid|
            date_str = params["date_notify_range_#{rid}_date_dropdown"]
            start_notify_time_str = params["date_notify_range_#{rid}_timepicker_start"]
            end_notify_time_str = params["date_notify_range_#{rid}_timepicker_end"]

            if date_str.blank? or start_notify_time_str.blank? or end_notify_time_str.blank?
                next
            elsif start_notify_time_str == end_notify_time_str
                next
            else
                chron_date = Chronic.parse(date_str)
                chron_start = Chronic.parse("#{date_str} at #{start_notify_time_str}")
                chron_end = Chronic.parse("#{date_str} at #{end_notify_time_str}")
                if chron_end < chron_start
                    puts "End time before start time, skipping."
                    next
                end
            end

            puts "#{date_str} at #{start_notify_time_str}"
            puts "#{date_str} at #{end_notify_time_str}"

            notify_prefs << {
                :date => chron_date,
                :start_notify => chron_start,
                :end_notify => chron_end,
            }
        end

        if jsonify
            notify_prefs = notify_prefs.to_json
        end

        return notify_prefs
    end

    def watch_params
        params.require(:watch).permit(:search_start_date, :search_end_date, :party_size, :search_time_id, :restaurant_id, :enabled, :title)
    end

    def watch_params_sticky
        params.require(:watch).permit(:party_size, :enabled, :title)
    end
end
