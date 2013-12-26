# coding: utf-8

require 'nokogiri'
require 'open-uri'
require 'ruby-readability'

module Goal
  class Article
    attr_accessor :title
    attr_accessor :url
    attr_writer :content

    MARK_UPS = ["p", "div", "span"]
    
    def initialize(title, url, content=nil)
      @title = title
      @url = url
      @content = content
    end

    def content
      @content ||= fetch_from_url
    end

    def fetch_from_url
      raw_html = open(@url).read
      with_markup = Readability::Document.new(raw_html, encoding: "UTF-8").content
      remove_markup(with_markup)
    end

    def remove_markup(str)
      @@mark_up_regex ||= build_mark_up_regex
      str.gsub(@@mark_up_regex, '')
    end

    def build_mark_up_regex
      str = ''
      MARK_UPS.each do |mark_up|
        str += '|' unless str.empty?
        str += "<#{mark_up}>|</#{mark_up}>"
      end
      Regexp.new str
    end

    def self.from_rss(feed, num)
      rss = open(feed)
      doc = Nokogiri::XML(rss)
      items = doc.xpath('//item').first(num)
      items.map do |item|
        title = item.search('title').first.content
        link = item.search('link').first.content
        Article.new(title, link)
      end
    end
  end
end
