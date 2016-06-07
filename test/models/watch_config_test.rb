class WatchConfigTest < ActiveSupport::TestCase
	fixtures :watch_configs

	test "should return watch config" do
		crt = WatchConfig.new  :cfg_raw => watch_configs(:crt_watch_config).cfg_raw,
		:cfg_hash => watch_configs(:crt_watch_config).cfg_hash,
		:restaurant_id => watch_configs(:crt_watch_config).restaurant_id,
		:scan_cooldown => watch_configs(:crt_watch_config).scan_cooldown

		assert crt.save
		crt_copy = WatchConfig.find(crt.id)
		assert_equal crt.cfg_hash, crt_copy.cfg_hash
		crt.restaurant_id = "4"

		assert crt.save
		assert crt.destroy

	end
end