require 'sinatra'
require 'rack'
require 'digest/md5'
require 'sdbm'
require 'dotenv'
require 'mysql2-cs-bind'
require 'json'

module Gyazo
  class Controller < Sinatra::Base
    Dotenv.load

    configure do
      set :image_dir, 'public/images'
      set :image_url, ENV['SERVER_URL']
      set :access_token, ENV['ACCESS_TOKEN']
      mime_type :png, 'image/png'
    end

    helpers do
      def db
        Mysql2::Client.new(
          :host => ENV['DB_HOST'],
          :username => ENV['DB_USER'],
          :password => ENV['DB_PASS'],
          :database => ENV['DB_NAME']
        )
      end

      def protect!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        username = ENV['BASIC_AUTH_USERNAME']
        password = ENV['BASIC_AUTH_PASSWORD']
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [username, password]
      end
    end

    before { protect! if request.path_info == "/history" }

    post '/upload' do
      auth = request.env['HTTP_AUTHORIZATION']
      if auth != 'Bearer ' + settings.access_token then
        return status 403
      end

      id = request[:id]
      data = request[:imagedata][:tempfile].read
      hash = Digest::MD5.hexdigest(data).to_s
      File.open("#{settings.image_dir}/#{hash}.png", 'w'){|f| f.write(data)}

      db.xquery('INSERT INTO images (hash, created_at) VALUES (?, ?)', hash, Time.now)

      "#{settings.image_url}/#{hash}.png"
    end

    get '/*.png' do |hash|
      send_file "#{settings.image_dir}/#{hash}.png"
    end

    get '/list' do
      auth = request.env['HTTP_AUTHORIZATION']
      if auth != 'Bearer ' + settings.access_token then
        return status 403
      end

      result = db.query('SELECT hash FROM images ORDER BY created_at DESC')
      result.to_a.map { |e| e['hash'] }.to_json
    end

    get '/history' do
      send_file "#{settings.public_dir}/history.html"
    end
  end
end
