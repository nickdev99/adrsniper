require 'chronic'
require 'active_support/core_ext/numeric/time'

Time.zone = "America/New_York"
Chronic.time_class = Time.zone

class UserMailer < ActionMailer::Base
  default from: "notify@wdwtools.com"

  def res_avail_notify(user, watch, times)
      @user = user
      times_parsed = []
      times.each do |t|
          l = []
          l << Chronic.parse(t[0])
          l << t[1]
          times_parsed << l
      end
      @times = times_parsed
      @watch = watch
      mail(to: @user.email, subject: "Reservation available.")
  end

  def watch_activated(user, watch)
     @user = user
     @watch = watch
     mail(to: @user.email, from: "order-confirm@wdwtools.com", subject: "Watch activated!")
  end
end
