#!/usr/bin/env ruby

require "mysql2.rb"
require "gdata.rb"
require "aws/s3.rb"

require File.expand_path(File.dirname(__FILE__) + '/../conf/ytl_conf.rb')

AWS::S3::DEFAULT_HOST = $config[:s3_server]

def create_entry(cfg={})
entry = <<EOF
<entry xmlns="http://www.w3.org/2005/Atom"
  xmlns:media="http://search.yahoo.com/mrss/"
  xmlns:yt="http://gdata.youtube.com/schemas/2007">
  <media:group>
    <media:title type="plain">#{cfg[:title]}</media:title>
    <media:description type="plain">
      #{cfg[:description]}
    </media:description>
    <media:category
      scheme="http://gdata.youtube.com/schemas/2007/categories.cat">People
    </media:category>
    <media:keywords>#{cfg[:keywords]}</media:keywords>
  </media:group>
</entry>
EOF
end

def split_video(filename)
  result=[]
  #Get video duration
  output = `ffmpeg -i #{filename} 2>&1`
  if output =~ /Duration: ([\d][\d]):([\d][\d]):([\d][\d]).([\d]+)/
    hours = $1
    mins = $2
    seconds =$3

    #Split video to chunks_number
    duration = $config[:video_chunk_duration]
    chunks_number = (hours.to_i*60 + mins.to_i)/duration
    puts "Chunks number: #{chunks_number}"
    
    extension = File.extname(filename)
    basename = File.basename(filename, '.*')  

    if chunks_number>0
      for i in 00..chunks_number
        chunk_name = basename + '_' + i.to_s + extension
        output = `ffmpeg -i #{filename} -sameq -ss 00:#{i*duration}:00 -t 00:#{duration}:00 #{chunk_name}`

        success = $?.success?
        puts "Success: " + success.to_s
        
        if success && $?.exitstatus == 0
          puts "Converted #{chunk_name}..."
          result << chunk_name
        else
          puts "Failed conversion of #{chunk_name}"
          return [] 
        end
      end
    else
      return [filename]
    end
  else
    puts "Failed: can't determine duration for #{filename}"
  end

  return result
end

def post_file(yt, entry, filename, content_type)
  response = yt.post_file($config[:yt_feed], filename, content_type, entry).to_xml
  puts "YT response: " + response.to_s
end

def download_video(url, bucket, bucket_name=$config[:s3_bucket_name])
  object = bucket[url]

  unless object.nil?
    puts 'Downloading from ' + object.url + '...'
    filename = url.gsub('/','_')

    open(filename, 'wb') do |file|
      object.value do |chunk|
        file.write chunk
      end 
    end
  else
    puts 'Requested object not found'
  end

  return filename;
end

def connect_to_yt
  yt = GData::Client::YouTube.new
  yt.source = $config[:yt_source] 
  yt.clientlogin($config[:yt_login], $config[:yt_password])
  yt.developer_key = $config[:yt_developer_key]
  return yt
end

def connect_to_s3(bucket_name=$config[:s3_bucket_name])
  puts 'Establishing connection with ' + $config[:s3_server] + '...'

  AWS::S3::Base.establish_connection!(
    :access_key_id     => $config[:s3_access_key_id], 
    :secret_access_key => $config[:s3_secret_access_key]
    )
  
  puts 'Obtaining bucket ' + bucket_name + '...'
  bucket = AWS::S3::Bucket.find(bucket_name)
  return bucket
end
