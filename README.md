At the moment, api keys/secrets are by default read from lazily constructed "[key] = [value]" .secret files
##metadata_api.rb
Uses the metadata API to:
* read a bib by OCN (provide OCN, get bib as ruby-marc and marcxml)
###metadata_sample.rb
helper documentation by example
##search_api.rb
Uses the search API to:
* read a bib by OCN (provide OCN, get bib as ruby-marc and marcxml)
* search via access method (provide access method query, get list of search results)
* get full bibs from list of search results
###search_sample.rb
helper documentation by example
## scripts using the API
###wcm\_collection_merge.rb
Merges OCNs from two wcm collection kbarts. Uses metadata API to find current OCN when the kbarts disagree. Ought to be made to only report titles needing correction (rather than reconstruct a correct kbart) per OCLC.
###am\_batch_search.rb
Given a list of "access method" queries, uses search API to find the "best" english-cataloging record. Varying the options provides varying "best" records, and we found that the varying quality of the best records leads us to prefer human-led locating (and correcting where needed) records when quantity permits. Is likely to find few matches on new, frontlist material.
