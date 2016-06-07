class RestaurantTest < ActiveSupport::TestCase
	fixtures :restaurants

	test "should return restaurant" do
		crt = Restaurant.new  :name => restaurants(:crt_restaurant).name,
		:lookup_id => restaurants(:crt_restaurant).lookup_id,
		:main_url => restaurants(:crt_restaurant).main_url,
		:pricing_in_res => restaurants(:crt_restaurant).pricing_in_res,
		:img_name => restaurants(:crt_restaurant).img_name,
		:event_only_venue => restaurants(:crt_restaurant).event_only_venue

		assert crt.save
		crt_copy = Restaurant.find(crt.id)
		assert_equal crt.lookup_id, crt_copy.lookup_id
		crt.main_url = "4.com"

		assert crt.save
		assert crt.destroy

	end
end