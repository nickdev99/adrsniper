require 'test_helper'

class ProductWatchTest < ActiveSupport::TestCase
	fixtures :product_watches

# When uncommented, the below code causes the following error:
# ActiveRecord::FixtureClassNotFound: No class attached to find
#
#	test "should return watches product" do
#		crt = ProductWatches.new  :product_id => product_watches(:crt_product_watch).product_id,
#		:days_avail => product_watches(:crt_product_watch).days_avail,
#		:sticky_days => product_watches(:crt_product_watch).sticky_days,
#		:lifetime_in_days => product_watches(:crt_product_watch).lifetime_in_days
#
#		assert crt.save
#		crt_copy = ProductWatches.find(crt.id)
#		assert_equal crt.days_avail, crt_copy.days_avail
#		crt.sticky_days = "4"
#
#		assert crt.save
#		assert crt.destroy
#
#	end
end