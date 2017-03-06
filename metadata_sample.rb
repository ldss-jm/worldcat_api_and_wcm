load './metadata_api.rb'

# Make an instance of MetadataAPI and load secrets/keys in './metadata.secret'
#
api = MetadataAPI.new(@prod_secret)


# Or, provide path to alternate secret file and create instance
#
secretfile = 'metadata.secret'
api = MetadataAPI.new(secretfile)


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
