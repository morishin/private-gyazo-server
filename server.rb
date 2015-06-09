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
      set :image_dir, 'public'
      set :image_url, ENV['SERVER_URL']
      set :access_token, ENV['ACCESS_TOKEN']
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
    end

    post '/upload' do
      auth = request.env['HTTP_AUTHORIZATION']
      if auth != 'Bearer ' + options.access_token then
        return status 403
      end

      id = request[:id]
      data = request[:imagedata][:tempfile].read
      hash = Digest::MD5.hexdigest(data).to_s
      File.open("#{options.image_dir}/#{hash}.png", 'w'){|f| f.write(data)}

      db.xquery('INSERT INTO images (hash, created_at) VALUES (?, ?)', hash, Time.now)

      "#{options.image_url}/#{hash}.png"
    end

    get '/' do
      auth = request.env['HTTP_AUTHORIZATION']
      if auth != 'Bearer ' + options.access_token then
        return status 403
      end

      result = db.query('SELECT hash FROM images ORDER BY created_at DESC')
      result.to_a.map { |e| e['hash'] }.to_json
    end
  end
end
