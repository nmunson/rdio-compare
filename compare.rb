require 'rubygems'
require 'nokogiri'
require 'lib/rdio'
require 'rdio_consumer_credentials'

class RdioCompare

  def initialize
    @user = ARGV[0]
    @itunes_library = ARGV[1]
    connect_to_rdio
  end

  def compare_libraries
    rdio_list = rdio_album_list
    itunes_list = itunes_album_list

    missing_albums_in_itunes = rdio_list.map{|i| i.downcase} - itunes_list.map{|i| i.downcase}

    puts missing_albums_in_itunes.sort
    puts "Total missing: " + missing_albums_in_itunes.length.to_s
  end

  private

  def connect_to_rdio
    @rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET])
    @user_key = @rdio.call('findUser', {'vanityName' => @user})["result"]["key"]
  end

  def rdio_album_list
    albums = @rdio.call('getAlbumsInCollection', {'user' => @user_key})
    albums["result"].collect{ |album| album["artist"] + " - " + album["name"]}
  end

  def itunes_album_list
    doc = Nokogiri::XML(File.open(@itunes_library))
    
    list = []

    doc.xpath('/plist/dict/dict/dict').each do |node|
      hash = {}
      last_key = nil

      node.children.each do |child|
        next if child.blank?
        if child.name == 'key'
          last_key = child.text
        else
          hash[last_key] = child.text
        end
      end

      list << hash
    end
    list.collect{ |node| "#{node['Artist']} - #{node['Album']}" }.uniq
  end

end

rdio_compare = RdioCompare.new
rdio_compare.compare_libraries

