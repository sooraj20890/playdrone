#!../script/rails runner

result = App.index('2013*').search(
  :size => 0,
  :query => { :match_all => {} },
  :facets => {
    :in => {
      :date_histogram => {
        :key_field => :crawled_at,
        :value_script => "doc['market_released'].value == 'T' ? 1 : 0",
        :interval => :day
      }
    },

    :out => {
      :date_histogram => {
        :key_field => :crawled_at,
        :value_script => "doc['market_removed'].value == 'T' ? 1 : 0",
        :interval => :day
      }
    },

    :updated => {
      :date_histogram => {
        :key_field => :crawled_at,
        :value_script => "doc['apk_updated'].value == 'T' ? 1 : 0",
        :interval => :day
      }
    }
  }
)

data = {}
result.facets.in['entries'].size.times.each do |i|
  day_in      = result.facets.in['entries'][i]
  day_out     = result.facets.out['entries'][i]
  day_updated = result.facets.updated['entries'][i]

  day = day_in['time'] / 1000
  if Time.at(day).to_date <= Date.parse("2013-04-26")
  elsif Time.at(day).to_date == Date.parse("2013-05-05")
  elsif Time.at(day).to_date == Date.parse("2013-05-06")
  elsif Time.at(day).to_date == Date.parse("2013-06-03")
  elsif Time.at(day).to_date == Date.parse("2013-06-04")
  elsif Time.at(day).to_date == Date.parse("2013-06-05")
  elsif Time.at(day).to_date == Date.parse("2013-11-24")
    # no good data
    nil
  else
    data[Time.at(day).to_date] = [day_in['total'], day_out['total'], day_updated['total']]
  end
end

start_day = Date.parse("2013-04-26")
File.open(ARGV[0], 'w') do |f|
  (data.keys.min .. data.keys.max).each do |day|
    if data[day]
      f.puts [(day - start_day).to_i, data[day]].join(' ')
    else
      f.puts [(day - start_day).to_i, "?", "?", "?"].join(' ')
    end
  end
end
