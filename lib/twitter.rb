# our twitter part

require 'twitter'
require 'oauth'
require 'yaml'
require_relative 'tweet'

# Our connection Twitter
# All methods are class side since this is only for one user
# no need for an instance
class TwitterConnection

  TWITTER_URL = "https://twitter.com/#!/"
  TWITTER_API_URL = "https://api.twitter.com"
  CREDENTIALS_FILE = 'preferences/twitter_credentials.yml'
  DEFAULT_TWEETS_TO_LOAD = 10

  # gets the request token
  # returns the url the user has to visit in order to authorize the app
  def self.get_request_token
    load_credentials_file
    @consumer = OAuth::Consumer.new(@credentials['consumer_key'],
                                    @credentials['consumer_secret'],
                                    :site => TWITTER_API_URL)
    @request_token = @consumer.get_request_token
    @request_token.authorize_url
  end

  # complete the authentication with the pincode
  def self.complete_authentication(pincode)
    @access_token = @request_token.get_access_token :pin => pincode

    # save the access token to our yaml file
    @credentials['oauth_token'] = @access_token.token
    @credentials['oauth_secret'] = @access_token.secret
    File.open CREDENTIALS_FILE, 'w' do |file|
      YAML.dump(@credentials, file)
    end
  end

  def self.load_credentials_file
    File.open(CREDENTIALS_FILE) do |file|
      @credentials = YAML::load(file)
    end
  end

  # load the credentials and configure the twitter gem to use them
  def self.load_credentials
    load_credentials_file
    Twitter.configure do |config|
      config.consumer_key = @credentials['consumer_key']
      config.consumer_secret = @credentials['consumer_secret']
      config.oauth_token = @credentials['oauth_token']
      config.oauth_token_secret = @credentials['oauth_secret']
    end
  end

  def self.tweets(number= DEFAULT_TWEETS_TO_LOAD)
    load_credentials
    if already_authenticated?
      Twitter.home_timeline[0...number].map { |tweet| Tweet.new(tweet) }
    else
      # if we're not authenticated, we can't show tweets
      []
    end
  end

  # Determine whether the user is already authenticated with infoes
  # therefore check for the presence of the user specific token and secret
  def self.already_authenticated?
    @credentials['oauth_token'] && @credentials['oauth_secret']
  end

end

