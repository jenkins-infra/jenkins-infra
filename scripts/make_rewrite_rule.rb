#!/usr/bin/env ruby

require 'optparse'

parser = OptionParser.new do |opts|
  opts.banner = "Usage: make_rewite_rule.rb source target"
end
parser.parse!

source, target = ARGV.map { |uri| URI.parse(uri) }

if !source
  puts "Missing source"
  puts parser.to_s
  exit(1)
end

if !target
  puts "Missing target url"
  puts parser.to_s
  exit(1)
end

if !target.absolute?
  puts "Target url must be complete with https://hostname/url"
  puts parser.to_s
  exit(1)
end

puts "RewriteRule \"^#{Regexp.quote(source.path)}$\" \"#{target.to_s}\" [NE,NC,L,QSA,R=301]"
puts 'RewriteCond %{HTTP_USER_AGENT} !^jenkins-wiki-exporter/(.*)$'
