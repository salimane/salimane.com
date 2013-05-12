require "bundler"
require "kramdown"
require "sanitize"
require "lib/uuid"
require "date"
require 'ostruct'
require 'yaml'

#require "lib/uuid"

###
# Site-wide settings
###

activate :livereload
activate :i18n, :mount_at_root => :en

@website = OpenStruct.new(YAML::load_file(File.dirname(__FILE__) + "/config.yaml")[:website])

# Create an RFC4122 UUID http://www.ietf.org/rfc/rfc4122.txt
set :uuid, UUID.create_sha1('salimane.com', UUID::NameSpace_URL)

# Compass
compass_config do |config|
  config.output_style = :expanded
end

###
# Blog settings
###

Time.zone = "Asia/Shanghai"

activate :blog do |blog|
  # set options on blog
  blog.layout = "post"
  blog.permalink = "posts/:title"
end

# Assemble resources to generate posts pages, Atom & JSON feeds
ready do
  posts_resources = []
  blog.articles.group_by {|a| a.date.year }.each do |year, year_posts|
    posts_resources << {:year => year, :articles => year_posts}
  end
  page "/posts.html", :layout => :generic do
    @archives = posts_resources
  end
  blog.articles.each do |a|
    page "#{a.url}atom.xml", :proxy => "/atom_single.xml", :layout => false, :ignore => true do
      @atom_post = a
    end
    page "#{a.url}atom.json", :proxy => "/json_single.json", :layout => false, :ignore => true do
      @atom_post = a
    end
  end
end

activate :directory_indexes

set :markdown_engine, :kramdown
set :markdown, :layout_engine => :haml,
:autolink => true,
:smartypants => true

###
# Page command
###

#page "/index.html", :layout => :generic
page "404.html", :layout => false
page "/posts/index.html", :layout => false
page "/sitemap.xml", :layout => "sitemap.xml"
page "/feed.rss", :layout => "feed.rss"
page "/atom.xml", :layout => "atom.xml"
page "/atom.json", :proxy => "/json_articles.json", :layout => false, :ignore => true do
  @atom_article = ''
end

###
# Code Highlighting
###

use Rack::Codehighlighter,
:pygments_api,
:element => "pre>code",
:pattern => /\A:::([-_+\w]+)\s*\n/,
:markdown => true

###
# Haml
###

# CodeRay syntax highlighting in Haml
# First: gem install haml-coderay
require 'haml-coderay'

# CoffeeScript filters in Haml
# First: gem install coffee-filter
# require 'coffee-filter'

###
# Helpers
###

# Methods defined in the helpers block are available in templates
helpers do
  # Properly format a content_entry_asset
  def entry_asset(img, url = nil)
    img_tag = image_tag img[:url], :itemprop => "image", :alt => img[:alt], :title => img[:title]
    unless url.nil?
      img_tag = link_to img_tag, url
    end
    '<div class="entry-content-asset photo-full">' + img_tag + '</div>'
  end

  # Strip all HTML tags from string
  def strip_tags(html)
    Sanitize.clean(html.strip).strip
  end

  # Calculate the years for a copyright
  def copyright_years(start_year)
    end_year = Date.today.year
    if start_year == end_year
      start_year.to_s
    else
      start_year.to_s + '-' + end_year.to_s
    end
  end

  # Holder.js image placeholder helper
  def img_holder(opts = {})
    return "Missing Image Dimension(s)" unless opts[:width] && opts[:height]
    return "Invalid Image Dimension(s)" unless opts[:width].to_s =~ /^\d+$/ && opts[:height].to_s =~ /^\d+$/

    img  = "<img data-src=\"holder.js/#{opts[:width]}x#{opts[:height]}/auto"
    img << "/#{opts[:bgcolor]}:#{opts[:fgcolor]}" if opts[:fgcolor] && opts[:bgcolor]
    img << "/text:#{opts[:text].gsub(/'/,"\'")}" if opts[:text]
    img << "\" width=\"#{opts[:width]}\" height=\"#{opts[:height]}\">"

    img
  end

  def all_posts
    posts = Dir["source/posts/*.html.*"]
    sorted_posts = posts.sort_by { |filename| File.mtime(filename) }

    return sorted_posts
  end

  def path_to_link(path)
    file = path.split("/").last
    title = file.sub(/\.haml/,"")
    "posts/#{title}"
  end

  def path_to_title(path)
    file = path.split("/").last
    title = file.split(".").first
    title.gsub(/-/," ").capitalize
  end

end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do

  # Automatic image dimensions on image_tag helper
  activate :automatic_image_sizes

  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable Uniquely-named assets
  activate :asset_hash

  # Use relative URLs
  activate :relative_assets

  # Compress PNGs after build
  # require "middleman-smusher"
  activate :smusher

  activate :image_optim

  #Minify HTML
  activate :minify_html

  #GZIP text files
  activate :gzip

  # Change Compass configuration
  compass_config do |config|
    config.output_style = :compressed
  end

  # Make favicons
  #activate :favicon_maker

end
