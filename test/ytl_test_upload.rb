#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../core/ytl_core.rb')

yt = connect_to_yt
unless yt.nil?
  filenames = ['media3_0.mp4', 'media3_1.mp4'] 
  multipart = filenames.size > 1

  filenames.each_with_index do |filename, i| 
    if multipart 
      part_name = " (part #{i+1})"
    else
      part_name = ""
    end
    entry = create_entry({:title => 'name' + part_name, :description => 'description' + part_name, :keywords => 'sotv'})
    post_file(yt, entry, filename, 'video/mp4')
  end
else
  puts 'Connection failed'
end
