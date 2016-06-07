class SearchTimeTest < ActiveSupport::TestCase
	fixtures :search_times

	test "should return search meal" do
		crt = SearchTime.new  :name => search_times(:crt_search_time).name

		assert crt.save
		crt_copy = SearchTime.find(crt.id)
		assert_equal crt.name, crt_copy.name
		crt.name = "Lunch"

		assert crt.save
		assert crt.destroy

	end
end