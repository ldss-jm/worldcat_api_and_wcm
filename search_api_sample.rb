load './search_api.rb'


# Provide path to secret file
#
secretfile='search.secret'

# Make an instance of SearchAPI and load secrets/keys
#
api = SearchAPI.new
api.get_keys(secretfile)

#Pass OCLC numbers to get current OCLC numbers
#
recnum = '46394151'
puts api.current_oclc(recnum)

recnum = '2416076'
puts api.current_oclc(recnum)
