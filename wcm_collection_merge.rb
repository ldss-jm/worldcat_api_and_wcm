
#logic
#write m to file
#n - if one is blank, use the other, if neither is blank
    #check for current oclc, if stock or custom is current, write to file using current,
    #if neither is current, but both have matching currents, use current
    #if neither is current, and they have non-matching currents, investigate?
#only in stock - write to file
#only in custom - discard



require 'csv'
load './search_api.rb'


##############################
secretfile = 'search.secret'
#Note: import utf-8 encoded files
custom_file = 'discontinued_upennback_UTF-8.txt'
stock_file = 'stock_upennback_UTF-8.txt'
outfile = 'output_wcm_coll_merge.txt'
problemfile = 'output_PROBLEMS_wcm_coll_merge.txt'
matchpoint = 'title_url'
##############################

def tabdelim_to_hash(filename, desired_index=nil, retain_headers=false)
  hash_index = 0
  headers = []
  titles = {}
  File.readlines(filename).each do |line|
    if headers.empty?
      headers = line.rstrip.split("\t")
      if desired_index
        hash_index = headers.index(desired_index)
      end
    else
      record = line.rstrip.split("\t")
      titles[record[hash_index]] = headers.zip(record).to_h
    end
  end
  if retain_headers
    return titles, headers
  else
    return titles
  end
end

def compare_lists(stockhash, customhash)
  match = []
  no_match = []
  only_in_stockhash = []
  stockhash.each do |key, value|
    if customhash.has_key?(key)
      if customhash[key]['oclc_number'] == value['oclc_number']
        match << value
        puts 'match'
      else
        value['custom_oclc'] = customhash[key]['oclc_number']
        no_match << value
        puts 'no match'
      end
    else
      only_in_stockhash << value
      puts 'only in stockhash'
    end
  end
  return match, no_match, only_in_stockhash
end

def flatten_record(record, headers)
  #converts a hash (record) into an array based on key order (headers)
  flat = []
  headers.each do |header|
    flat << record[header]
  end
  return flat
end


if File.exists?(outfile)
  File.delete(outfile)
end
if File.exists?(problemfile)
  File.delete(problemfile)
end

api = SearchAPI.new
api.get_keys(secretfile)



custom = tabdelim_to_hash(custom_file, matchpoint)
stock, headers = tabdelim_to_hash(stock_file, matchpoint, retain_headers=true)
m, n, o = compare_lists(stock, custom) #  m,n,o = match, nonmatch, only_in_stock




# manual bom writing from:
# https://stackoverflow.com/questions/9886705/how-to-write-bom-marker-to-a-file-in-ruby#9887927
File.open(outfile, 'w', 0644) do |file|
  file.write "\uFEFF"
end
File.open(problemfile, 'w', 0644) do |file|
  file.write "\uFEFF"
end

problems = []
CSV.open(outfile, 'a', {:col_sep => "\t"}) do |c|
  #write headers
  c << headers
  #write m, o
  (m+o).each do |record|
    c << flatten_record(record, headers)
  end
  #write n
  n.each do |record|
    good_num = ''
    stock_num = record['oclc_number']
    custom_num = record['custom_oclc']
    if stock_num.empty?
      good_num = custom_num # if stock empty: custom; if both empty: empty
    elsif custom_num.empty?
      good_num = stock_num # if custom empty: stock
    else
      stock_current = api.current_oclc(record['oclc_number'])
      custom_current = api.current_oclc(record['custom_oclc'])
      if stock_current == custom_current
        good_num = stock_current
      else
        custom_record = custom[record[matchpoint]]
        problems << flatten_record(record,headers) + ['stock', stock_current]
        problems << flatten_record(custom_record,headers) + ['custom', custom_current]
      end
    end
    record['oclc_number'] = good_num
    record.delete('custom_oclc')
    if not good_num.empty?
      c << flatten_record(record, headers)
    end
  end
end

#write problemfile headers
CSV.open(problemfile, 'a', {:col_sep => "\t"}) do |c|
  c << headers + ['wcm_list', 'current_OCLC_from_api']
  problems.each do |p|
  c << p
  end
end
