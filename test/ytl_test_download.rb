#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../core/ytl_core.rb')

AWS::S3::DEFAULT_HOST = $config[:s3_server]

puts 'Establishing connection with ' + $config[:s3_server] + '...'

AWS::S3::Base.establish_connection!(
  :access_key_id     => $config[:s3_access_key_id], 
  :secret_access_key => $config[:s3_secret_access_key]
  )


bucket_name = $config[:s3_bucket_name]
puts 'Obtaining bucket ' + bucket_name + '...'

bucket = AWS::S3::Bucket.find(bucket_name)
unless bucket.nil?
  puts 'Bucket found'
      
  url = 'families/2011-12-20/master_vlast_semei_13_12_2011.mp4'
  filename = download_video(url, bucket, bucket_name)
  unless filename.nil?
    puts 'Test passed!'
  else
    puts 'Test failed'
  end
else
  puts 'Bucket not found'
end
