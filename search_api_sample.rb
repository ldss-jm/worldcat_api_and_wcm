load './search_api.rb'

# Make an instance of SearchAPI and load secrets/keys in './search.secret'
#
api = SearchAPI.new(@prod_secret)


# Or, provide path to alternate secret file and create instance
#
secretfile='search.secret'
api = SearchAPI.new(secretfile)

# Test authentication, optionally
#
api.test_auth()

# Read/retrieve a bib via OCLC number
#
recnum = '46394151'
# Retrieve bib from API and store it...  
puts api.read_bib('46394151')
# ...as a marc-ruby Record...
puts api.bib
puts api.bib['001'].value
puts api.bib.fields('650')
# ...and as marcxml
puts api.bib.xml



# Pass OCLC number to get current OCLC number
#
recnum = '46394151'
puts api.current_oclc(recnum)

recnum = '2416076'
puts api.current_oclc(recnum)


# Perform search via access method (limited to 100 results)
#   search is also restricted (by us) to mt:elc and mt:bks
#
am='cbo9780511731990'
api.am_search(am)
# Perform search via access method but restrict results to holding_libs > "limit"
api.am_search(am, limit=5)
# Return those results again
api.results
# Retrieve a full bib record for each result
api.get_detailed_results
# Return the hash of full records (as marc-ruby Records)
api.results.full_records
# Get the marcxml for one of the Records
api.results.full_records[0].xml

# Get a hash of the best (by elvl) records with english cataloging
api.results.best_english
