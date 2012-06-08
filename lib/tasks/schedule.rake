require 'nokogiri'
require 'open-uri'
require 'schedule.rb'

namespace :schedule do

  task :test => :environment do
    Schedule::process_schedule_page(Nokogiri::HTML(open("http://localhost/~dementrock/schedule.html")))
  end

  task :update_courses => :environment do
    term = "FL"
    raw_schedule_url = "http://osoc.berkeley.edu/OSOC/osoc?p_term=%{term}&p_classif=%{classif}&p_start_row=%{start_row}"

    Schedule::CLASSIFS.each_key do |classif|
      puts "fetching classification #{classif} with start_row #{1}"
      first_page_url = raw_schedule_url % {:term => term, :classif => classif, :start_row => 1}
      first_page = Nokogiri::HTML(open(first_page_url))
      total_count = first_page.xpath("//body/table").first.to_s.match(/Displaying \d+\-\d+ of (\d+)/)[1].to_i
      Schedule::process_schedule_page(first_page)
      (101..total_count).step(100).each do |start_row|
        puts "fetching classification #{classif} with start_row #{start_row}"
        page_url = raw_schedule_url % {:term => term, :classif => classif, :start_row => start_row}
        page = Nokogiri::HTML(open(page_url))
        Schedule::process_schedule_page(page)
      end
    end
  end
end
