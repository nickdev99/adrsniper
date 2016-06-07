class WatchTest < ActiveSupport::TestCase
	fixtures :watches
#
#
#
#	test "should return watch" do
#		crt = Watch.new  :search_start_date => watches(:crt_watch).search_start_date,
#		:search_end_date => watches(:crt_watch).search_end_date,
#		:party_size => watches(:crt_watch).party_size,
#		:search_time_id => watches(:crt_watch).search_time_id,
#		:restaurant_id => watches(:crt_watch).restaurant_id,
#		:user_id => watches(:crt_watch).user_id,
#		:cfg_hash => watches(:crt_watch).cfg_hash,
#		:last_crawl => watches(:crt_watch).last_crawl,
#		:enabled => watches(:crt_watch).enabled,
#		:expired => watches(:crt_watch).expired,
#		:last_notify => watches(:crt_watch).last_notify,
#		:notify_prefs => watches(:crt_watch).notify_prefs,
#		:paid => watches(:crt_watch).paid,
#		:title => watches(:crt_watch).title,
#		:user_obtained => watches(:crt_watch).user_obtained
#
#		assert crt.save
#		crt_copy = Watch.find(crt.id)
#		assert_equal crt.search_end_date, crt_copy.search_end_date
#		crt.party_size = "4"
#
#		assert crt.save
#		assert crt.destroy
#
#	end
end