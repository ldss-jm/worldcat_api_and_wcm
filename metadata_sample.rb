load './metadata_api.rb'

# Provide path to secret file
#
secretfile = 'metadata.secret'

# Make an instance of SearchAPI and load secrets/keys
#
api = MetadataAPI.new
api.get_keys(secretfile)

#Pass OCLC numbers to get a hash of the bib with marc tags as keys
#
recnum = '46394151'
api.read_bib(recnum)
puts api.bib
puts api.bib['001']