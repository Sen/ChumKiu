require 'sinatra/base'
require "sinatra/reloader"
require "sinatra/json"
require 'redis'

class Armoire < Sinatra::Base
  configure :development do
    $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
    Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") do |lib| 
      require File.basename(lib, '.*') 
    end

    register Sinatra::Reloader
  end

  helpers do
    def redis
      $redis ||= Redis.new(host: 'localhost', port: '6379')
    end

    def redis=(redis)
      $redis = redis
    end

    def protected!
      return if authorized?
      halt 401, "Not authorized\n"
    end

    def authorized?
      redis && redis.ping == 'PONG'
    end
  end

  post '/api/connect' do
    begin
      if params[:sock]
        redis = Redis.new(path: params[:sock])
      else
        redis = Redis.new(host: params[:host] || 'localhost',
                          port: params[:port] || '6379')
      end

      json redis.info
    rescue Exception => e
      status 401
      json error: e
    end
  end

  get '/api/info/?:type?' do
    begin
      protected!
      json redis.info(params[:type])
    rescue Exception => e
      status 401
      json error: e
    end
  end

  get '*' do
    File.read(File.join('public', 'index.html'))
  end

end
