class WdwToolsConfigTest < ActiveSupport::TestCase
	fixtures :wdw_tools_configs

	test "should return config" do
		crt = WdwToolsConfig.new  :key => wdw_tools_configs(:crt_wdw_tools_config).key,
		:value => wdw_tools_configs(:crt_wdw_tools_config).value

		assert crt.save
		crt_copy = WdwToolsConfig.find(crt.id)
		assert_equal crt.value, crt_copy.value
		crt.key = "4a"

		assert crt.save
		assert crt.destroy

	end
end