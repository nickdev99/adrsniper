class RefurbishmentTest < ActiveSupport::TestCase
	fixtures :refurbishments

	test "should return refurbishment" do
		crt = Refurbishment.new  :start_date => refurbishments(:crt_refurb).start_date,
		:end_date => refurbishments(:crt_refurb).end_date,
		:restaurant_id => refurbishments(:crt_refurb).restaurant_id

		assert crt.save
		crt_copy = Refurbishment.find(crt.id)
		assert_equal crt.end_date, crt_copy.end_date
		crt.restaurant_id = "4"

		assert crt.save
		assert crt.destroy

	end
end