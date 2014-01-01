#!/usr/bin/ruby
# coding: utf-8

require 'pstore'
require 'logger'

require './goal.rb'
require './yssy.rb'

FEED = 'http://www.goal.com/cn/feeds/team-news?id=94&fmt=rss&ICID=CP_94'
MAX_ARTICLES = 3
SECRET = 'secret.txt'
POSTED_STORE = 'posted.txt'
BOARD = 'arsenal'
LOG = 'arsy.log'

logger = Logger.new(LOG)

begin
  username = ''
  password = ''
  File.open(SECRET, 'r') do |file|
    username = file.gets.chomp
    password = file.gets.chomp
  end

  articles = Goal::Article.from_rss(FEED, MAX_ARTICLES)

  store = PStore.new(POSTED_STORE)
  posted = []
  store.transaction(readonly=true) do
    posted = store[:posted] || []
  end
  articles.reject! {|article| posted.include? article.url}
  logger.info("nothing to do") if articles.empty?

  Yssy.new(username, password) do |yssy|
    articles.each do |article|
      succ = yssy.post(BOARD, article.title, article.content)
      if succ
        posted << article.url
        logger.info "#{article.title} is successfully posted"
      else
        logger.error "#{article.title} failed to posted"
      end
    end
  end
  
  while posted.length > 10
    posted.shift
  end

  store.transaction do
    store[:posted] = posted
  end
rescue => e
  logger.fatal e.message
end
