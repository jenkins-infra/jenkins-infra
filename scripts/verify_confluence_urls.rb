#!/usr/bin/env ruby

# Verify the vhost.conf file for confluence

# Read the RewriteRule source entries, check them against a local file
# of known URLs.
#
# If not found in the local file, and not found in a file of known
# redirects for pages that do not exist, use an HTTP HEAD request to check
# the URL exists

require 'net/https'
require 'set'

filename_vhost="dist/profile/templates/confluence/vhost.conf"
filename_confluence_urls_without_a_page="scripts/confluence_urls_without_a_page"
filename_confluence_urls="scripts/confluence_urls"

return_code=0

confluence_urls = File.readlines(filename_confluence_urls).collect(&:chomp).to_set
confluence_urls_without_a_page = File.readlines(filename_confluence_urls_without_a_page).collect(&:chomp).to_set

def regex_to_url(regex)
  return regex.gsub(/\$$/, '').gsub(/^\^/, '').gsub(/\\/, '')
end

def check_uri(url)
  uri = URI("https://wiki.jenkins.io#{url}")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  req = Net::HTTP::Head.new(uri.request_uri, {
    'User-Agent': "jenkins-wiki-exporter/verify_confluence_urls"
  })
  response = http.head(uri.request_uri)

  case response
  when Net::HTTPOK, Net::HTTPMovedPermanently
    return true   # success response
  end
  message = response.code
  message += ' ' + response.message.dump if response.message
  raise StandardError.new(message)
end


File.foreach(filename_vhost) do |line|
  next unless line =~ /RewriteRule.*display/
  next if line =~ /^#/

  keyword, match, redirect, flags = line.chomp.split(/\s+/).collect { |part| part.gsub(/"(.*)"/, '\1') }
  match_regex = Regexp.new(match)

  # Found pattern in the list of working confluence pages
  next if confluence_urls.any? { |url| match_regex.match(url) }
  # Found pattern in the list of working confluence pages
  next if confluence_urls_without_a_page.any? { |url| match_regex.match(url) }

  uri = regex_to_url(match)
  begin
    check_uri(uri)
    puts "Adding https://wiki.jenkins.io#{uri} to confluence_urls"
    confluence_urls.add(uri)
    return_code=1
  rescue StandardError => err
    puts "HEAD for https://wiki.jenkins.io#{uri} failed: #{err}"
    confluence_urls_without_a_page.add(uri)
    return_code=2
  end
end

File.write(filename_confluence_urls, confluence_urls.to_a.sort_by(&:downcase).join("\n"))
File.write(filename_confluence_urls_without_a_page, confluence_urls_without_a_page.to_a.sort_by(&:downcase).join("\n"))

if return_code.to_i != 0; then
  puts "======================== Ruby: New redirect addition needs update to test data file ========================"
  system("git diff")
  puts "======================== Ruby: End of redirect addition update for test data file ========================"
end

exit(return_code.to_i)
