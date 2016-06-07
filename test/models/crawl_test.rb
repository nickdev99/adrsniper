class CrawlTest < ActiveSupport::TestCase
	fixtures :crawls

	test "should return a crawl" do
		crt = Crawl.new  :timestamp => crawls(:crt_crawl).timestamp,
		:proc_out => crawls(:crt_crawl).proc_out,
		:res_available => crawls(:crt_crawl).res_available,
		:watch_config_id => crawls(:crt_crawl).res_available

		assert crt.save
		crt_copy = Crawl.find(crt.id)
		assert_equal crt.timestamp, crt_copy.timestamp
		crt.proc_out = "new test"

		assert crt.save
		assert crt.destroy

	end
end