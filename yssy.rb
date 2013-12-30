# coding: utf-8

require 'net/http'

class Yssy

  LOGIN_URI = URI('http://bbs.sjtu.edu.cn/bbslogin')
  POST_URI = URI('http://bbs.sjtu.edu.cn/bbssnd')
  DEFAULT_OPTIONS = {'level' => 0, 'signature' => 1, 'autocr' => 'on', 'live' => 180}
  ENCODING = 'gb2312'

  def post(board, title, body, options={})
    data = DEFAULT_OPTIONS.merge options
    data['board'] = board
    data['title'] = title.encode(ENCODING)
    data['text'] = body.encode(ENCODING)
    
    post_req = Net::HTTP::Post.new(POST_URI.path)
    post_req.set_form_data(data)
    post_req['Cookie'] = @cookie
    
    post_res = Net::HTTP::start(POST_URI.hostname, POST_URI.port) do |http|
      http.request post_req
    end
    (post_res.is_a? Net::HTTPOK) && !(/ERROR:/ === post_res.body)
  end

  def initialize(username, password)
    login_res = Yssy.login(username, password)
    fail 'cannot login' unless login_res.is_a? Net::HTTPFound

    @cookie = Yssy.parse_cookie_from_response(login_res)
    yield self if block_given?
  end

  def self.login(username, password)
    login_req = Net::HTTP::Post.new(LOGIN_URI.path)
    login_req.set_form_data('id' => username, 'pw' => password)
    login_res = Net::HTTP::start(LOGIN_URI.hostname, LOGIN_URI.port) do |http|
      http.request login_req
    end
  end

  def self.parse_cookie_from_response(response)
    all_cookies = response.get_fields('set-cookie')
    all_cookies.map{|cookie| cookie.split('; ')[0]}.join('; ')
  end
end
