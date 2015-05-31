require 'sinatra'
require 'rack'
require 'digest/md5'
require 'sdbm'
require 'dotenv'

module Gyazo
  class Controller < Sinatra::Base
    Dotenv.load

    configure do
      set :image_dir, 'public'
      set :image_url, 'http://g.morishin.me'
      set :access_token, ENV['ACCESS_TOKEN']
    end

    post '/' do
      auth = request.env["HTTP_AUTHORIZATION"]
      if auth != "Bearer " + options.access_token then
        return status 403
      end
      id = request[:id]
      data = request[:imagedata][:tempfile].read
      hash = Digest::MD5.hexdigest(data).to_s
      File.open("#{options.image_dir}/#{hash}.png", 'w'){|f| f.write(data)}

      "#{options.image_url}/#{hash}.png"
    end
  end
end
