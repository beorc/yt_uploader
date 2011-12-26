#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/core/ytl_core.rb')

bucket = connect_to_s3
unless bucket.nil?
  puts 'Bucket found'
  
  yt = connect_to_yt
  unless yt.nil?
    dbh = Mysql2::Client.new(:host=> $config[:db_host], :username => $config[:db_username], :password => $config[:db_password], :database => $config[:db_database])
    unless dbh.nil?
      results = dbh.query("SELECT id, url, name, description FROM tv_shows WHERE yt_uploaded=FALSE AND NOT url IS NULL AND publishing_date < NOW()")
      results.each do |row|
        puts 'Processing ' + row['name'] + '...'
        url = row['url']
        filename = download_video(url, bucket)
        unless filename.nil?
          filenames = split_video(filename)
          multipart = filenames.size > 1

          unless filenames.empty?
            filenames.each_with_index do |filename, i| 
              if multipart 
                part_name = " (part #{i+1})"
              else
                part_name = ""
              end
              entry = create_entry({:title => row['name'] + part_name, :description => row['description'] + part_name, :keywords => 'sotv'})
              post_file(yt, entry, filename, object.content_type)
            end
            
            File.delete(filename)
            filenames.each {|fname| File.delete(fname) if File.exist?(fname)}

            results = dbh.query('UPDATE tv_shows SET yt_uploaded=TRUE WHERE id=' + row['id'])
          end
        else
          puts 'Video download failed'
        end
      end
    else
      puts 'Mysql connection failed'
    end

    dbh.close if dbh
    puts 'Processing complete'
  else
    puts 'Connection to YT failed'
  end
else
  puts 'Bucket not found'
end
