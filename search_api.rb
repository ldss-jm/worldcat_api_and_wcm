#!/usr/bin/env ruby
require 'net/http'
require 'marc'
require 'nokogiri'


#TODO get other valid http response codes
#TODO probably not needed to keep a separate SearchSession class anymore

@prod_secret = File.dirname(__FILE__).to_s + '/search.secret'

class SearchSession
  attr_reader :response

  def make_request(url, retry_on_error=true)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    @response = http.start do |http| 
      http.request(request)
    end
    #TODO get other valid http response codes
    if @response.code != '200' and retry_on_error
      puts 'http error, retrying'
      sleep(2)
      make_request(url, retry_on_error=false)
    end
    return @response
  end

  def test_auth(wskey)
    oclcnum = '46394151'
    url = 'http://www.worldcat.org/webservices/catalog/content/' +
           oclcnum + '?servicelevel=full&wskey=' + wskey
    status = make_request(url).code
    if status == '200'
      puts 'Authentication successful.'
      return true
    else
      puts 'Test authentication failed. Wrong credentials or ' +
           'worldcat service down?'
      return false
    end
  end
  
end


class SearchAPI
  attr_accessor :url
  attr_reader :response, :bib, :bib_xml, :results

  def initialize(secretfile)
    secrets = get_keys(secretfile)
    @wskey = secrets['wskey_lite']
    @session = SearchSession.new()
  end

  def get_keys(filename)
    secrets = {}
    lines = File.read(filename).split("\n")
    lines.each { |line| secrets[line.split(" = ")[0]] = line.split(" = ")[1].rstrip }
    return secrets
  end
  
  def read_bib(oclcnum)
    @url = 'http://www.worldcat.org/webservices/catalog/content/' +
           oclcnum + '?servicelevel=full&wskey=' + @wskey
    @response = @session.make_request(@url)
    if @response.code != '200'
      return nil
    end
    @bib = MARC::XMLReader.new(StringIO.new(@response.body)).first
    @bib.xml=@response.body
    return @bib
  end

  def am_search(access_method, limit=nil)
    @url= 'http://www.worldcat.org/webservices/catalog/search/worldcat/' +
          'opensearch?q=srw.am+all+' + access_method +
          '+and+srw.mt+all+"elc+bks"' +
          '&count=100&servicelevel=full&wskey=' + @wskey +
          '&frbrGrouping=off'
    if limit
      limit = limit.to_s.rjust(2, '0')
      @url = @url.sub('&count', "+and+srw.cg+any+#{limit}&count")
    end
    @response = @session.make_request(@url)
    @results = SearchResults.new(@response.body)
    if @response.code != '200'
      @results.http_error = true
    end
    return @results
  end
    
  def current_oclc(oclcnum)
    oclcnum = oclcnum.to_s
    read_bib(oclcnum)
    return @bib['001'].value
    return _001
  end
  
  def test_auth()
    @session.test_auth(@wskey)
  end
 
  def get_detailed_results()
    full_recs = []
    @results.ocns.each do |ocn|
      full_recs << read_bib(ocn)
      if @response.code != '200'
        @results.http_error = true
      end
    end
    @results.full_records = full_recs
  end

end

class SearchResults
  attr_reader :response, :bib_xml, :bib, :results
  attr_accessor :full_records, :http_error
  
  def initialize(results)
    @nokogiri = Nokogiri::XML(results)
  end
  
  def ocns()
    oclcnums = []
    @nokogiri.css('oclcterms|recordIdentifier').each do |ocn|
      oclcnums << ocn.text
    end
    return oclcnums
  end
  
  def best_english()
    english = []
    @full_records.each do |record|
      if record['040']['b'] == 'eng'
    english << record
      end
    end
    if english.empty?
      return nil
    end
    english.sort_by! { |x| x.elvl }
    best = english.group_by { |x| x.elvl }[(english[0].elvl)]
    return best
  end
end

class MARC::Record
  attr_reader :xml, :elvl
  
  def xml=(xml_record)
    @xml = xml_record
  end
  
  def elvl()
    mapping = {' ' => '0', 'I' => '0.I', '1' => '1', 'L' => '1.L', '2' => '2',
               'M' => '2.M', '4' => '4', '8' => '8', 'K' => '8.K', '7' => '917',
               '3' => '923', '5' => '935', 'J' => '94J'}
    return mapping[leader[17]]
  end
end

