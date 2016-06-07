# this would be ideal as an SQL file, but SQLite handles date comparisons
# against 'now' strangely. While this is probably inefficient, it's good
# enough for now; in production, we can switch to an SQL file when we have
# our production database firmly established. #FIXME.
ws = Watch.where("search_end_date < ?", Time.now)
ws.each do |w|
    puts "Expiring watch id #{w.id}, with an end date of #{w.search_end_date}"
    w.expired = 1
    w.save
end
