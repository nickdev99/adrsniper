class GroupTest < ActiveSupport::TestCase
	fixtures :groups

	test "should return group" do
		crt = Group.new  :code => groups(:crt_group).code,
		:name => groups(:crt_group).name,
		:discount_type => groups(:crt_group).discount_type,
		:discount_size => groups(:crt_group).discount_size,
		:uses_left => groups(:crt_group).uses_left

		assert crt.save
		crt_copy = Group.find(crt.id)
		assert_equal crt.name, crt_copy.name
		crt.discount_type = "Amount"

		assert crt.save
		assert crt.destroy

	end
end