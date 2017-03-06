load 'search_api.rb'

# Make an instance of SearchAPI and load secrets/keys
#
api = SearchAPI.new(@prod_secret)

# Load list of access method terms ('am_batch.txt')
# Output term, ocn, elvl ('am_batch_output.txt')
#
ams = File.read('am_batch.txt').split("\n")
i = 0
File.open('am_batch_output.txt', 'a') {|f|
  ams.each do |am|
    i += 1
    puts i.to_s + " / " + ams.length.to_s
    #api.am_search(am)
    api.am_search(am, limit=5)
    api.get_detailed_results
    if api.results.http_error
      # either the search results or the bib retrieval failed
      f.write([am, 'http error'].join("\t") + "\n")
    elsif not api.results.full_records.empty? and api.results.best_english
      if api.results.best_english.length > 1
        # multiple best records, search again and require holding_libs >= 5
        #api.am_search(am, limit=5)
        api.am_search(am, limit=10)
        api.get_detailed_results
      end
      if not api.results.best_english or api.results.best_english.length > 1 or api.results.full_records.empty?
        # still multiple best records, or no records, stop trying
        puts 'multiple'
        f.write([am, 'multiple', api.results.ocns.join("; ")].join("\t") + "\n")
      else
        # one record found, write results
        puts 'found'
        best = api.results.best_english[0]
        f.write([am, best['001'].value, best.elvl].join("\t") + "\n")
      end
    else
      #no acceptable records found
      puts 'no matches'
      f.write([am, 'no matches'].join("\t") + "\n")
    end
  end
}
