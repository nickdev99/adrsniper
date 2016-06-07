class Watch < ActiveRecord::Base
  belongs_to :search_time
  belongs_to :restaurant
  belongs_to :user
  belongs_to :watch_config, :foreign_key => 'cfg_hash', :primary_key => 'cfg_hash'

  before_save :update_watch_config

  validate :watch_not_expired, :start_not_greater, :refurb_dates

  FRIENDLY_DATE_FORMAT = "%B %e, %Y"
  FRIENDLY_TIME_FORMAT = "%l:%M %P"

#  def check_watched_days_limit
#      u = User.find(user_id)
#      puts "cwd: #{u.count_active_days([id])}"
#      watched_days = u.count_active_days([id]) + count_days
#      puts "wd: #{watched_days}"
#      max_watch_days = Watch.get_max_watched_days(user_id)
#      puts "mwd: #{max_watch_days}"
#      if watched_days > max_watch_days
#          errors[:base] << "Your quota of #{max_watch_days} cumulative watched days has been exceeded.\nYou may need to disable old watches, or choose a shorter date range to monitor."
#      end
#  end

  def active?
      if not watch_not_expired or not paid or search_period_pending?
          return false
      else
          return true
      end
  end

    def refurb_dates
      #@TODO: deal with multiple/historical refurb dates
      #@TODO: Accept singular closure dates -- Currently only supports ranges (closure will need to be at least 10 days or their
      # will be problems.)
      refurb = Refurbishment.where("restaurant_id = ? AND end_date > ?", restaurant_id, Time.now)
      if refurb.length > 0
        watch_range = (search_start_date..search_end_date)
        (refurb[0].start_date..refurb[0].end_date).each do |d|
          if watch_range.include?(d)
              errors[:base] << "Some or all of your selected dates are unavailable because the venues is closed."
              break
          end
        end
      end
  end

  def self.get_max_watched_days(user_id)
      current_user = User.find(user_id)

      max_watch_days = 0
      if current_user.has_elite
          pws = ProductWatches.all
          pws.each do |pw|
              if UserProduct.does_user_own?(user_id, pw.product_id)
                up = UserProduct.where("user_id = ? AND product_id = ?", user_id, pw.product_id)[0]
                if up.nil?
                  qty = 1
                else
                  qty = up.qty
                end
                  max_watch_days += (pw.days_avail * qty)
              end
              puts pw.days_avail
          end
      else
          max_watch_days = current_user.max_watch_days
      end

      return max_watch_days
  end

  def watch_not_expired
     if search_end_date.nil? or search_end_date < Date.today then
         errors[:search_end_date] << "Your search can't end in the past."
         return false
     else
         return true
     end
  end

  def search_period_pending?
      if (search_start_date - Date.today) > 180
          return true
      else
          return false
      end
  end

  def start_not_greater
      if search_end_date < search_start_date then
          errors[:search_start_date] << "You cannot end a search before you start it."
      end
  end

  def self.active
      where("enabled = 't' AND expired = 'f'")
  end

  def self.default_scope
      self.active
  end

  def count_days()
      if single_day?
          return 1
      end
      return (search_end_date - search_start_date).to_i + 1
  end

  def single_day?()
      return search_end_date == search_start_date ? true : false
  end

  def friendly_date_or_time_obj(d)
      return d.strftime(FRIENDLY_DATE_FORMAT)
  end

  def friendly_start_date()
      return friendly_date_or_time_obj(search_start_date)
  end

  def friendly_end_date()
      return friendly_date_or_time_obj(search_end_date)
  end

  def friendly_range_list()
      np = JSON.parse(notify_prefs)
      l = []
      puts np
      np.each do |p|
          start_time_obj = Chronic.parse("#{p['start_notify']}")
          end_time_obj = Chronic.parse("#{p['end_notify']}")
          date_obj = Chronic.parse("#{p['date']}")
          l << "#{date_obj.strftime(FRIENDLY_DATE_FORMAT)}, #{start_time_obj.strftime(FRIENDLY_TIME_FORMAT)} through #{end_time_obj.strftime(FRIENDLY_TIME_FORMAT)}"
      end
      return l
  end

  def update_watch_config()
    cfg_raw = build_scraper_config()
    self.cfg_hash = Digest::MD5.hexdigest(cfg_raw).force_encoding(Encoding::US_ASCII)
    puts "Watch CFG Hash: #{self.cfg_hash}\nWatch CFG Raw: #{cfg_raw}"

    if !WatchConfig.exists? :cfg_hash => self.cfg_hash then
        @watchcfg = WatchConfig.new()
        @watchcfg.cfg_raw = cfg_raw
        @watchcfg.cfg_hash = self.cfg_hash
        @watchcfg.save
    end
  end

  def build_scraper_config()
    return JSON.pretty_generate({
    :searchStartDate => search_start_date,
    :searchEndDate => search_end_date,
    :skipPricing => restaurant.pricing_in_res,
    :searchTime => search_time.name,
    :type => "dining",
    :partySize => party_size,
    :id => restaurant.lookup_id,
    :restaurantMainUrl => restaurant.main_url,
    :humanName => restaurant.name,
    })
  end
end
