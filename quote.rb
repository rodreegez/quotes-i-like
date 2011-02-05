# Use Heroku db if available, else use file in current dir
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/quote.db")

config = YAML.load_file('config.yml')

CLIENT_ID     = config['config']['client_id']
CLIENT_SECRET = config['config']['client_secret']
REDIRECT_URI  = config['config']['redirect_uri']
BASE_URI      = 'https://quotabl.es/api/v2'

class User
  include DataMapper::Resource
  property :id,           Serial
  property :image,        String
  property :access_token, String
  property :permalink,    String
  property :username,     String
end

DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  "<h1>Quotes I Like</h1>
  <p>Please sign in with Quotabl.es</p>
  <a href='https://quotabl.es/oauth/authorize?client_id=#{CLIENT_ID}&redirect_uri=#{REDIRECT_URI}&response_type=code'>Authorize Quotables</a>"
end

get '/oauth/callback' do
  response = HTTParty.post('https://quotabl.es/oauth/access_token', {
      :body => {
        :client_id => CLIENT_ID,
        :client_secret => CLIENT_SECRET,
        :code => params[:code],
        :grant_type => 'authorization_code',
        :redirect_uri => REDIRECT_URI
      }
    })
  response = response.parsed_response

  @user = User.first({:access_token => response['access_token']})

  unless @user.nil?
    redirect "/#{@user.permalink}"
  else
    @user = User.create({
      :access_token => response['access_token'],
      :image        => response['user']['image'],
      :permalink    => response['user']['permalink'],
      :username     => response['user']['username']
    })
    @user.save
    redirect "/#{@user.permalink}"
  end
end

get '/:permalink' do
  @user = User.first(:permalink => params[:permalink])

  quotes = HTTParty.get("#{BASE_URI}/users/#{@user.permalink}/quotes.json")
  quotes = quotes.parsed_response
  @quotes = quotes['quotes']
  erb :quote
end
