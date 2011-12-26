#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../core/ytl_core.rb')

filename = 'media3.mp4'
filenames = split_video(filename)

unless filenames.empty?
  puts 'Test passed!'
else
  puts 'Test failed'
end
