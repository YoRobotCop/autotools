require 'rack'
require 'ipinfo'

class IPinfoMiddleware
  def initialize(app, cache_options = {})
    @app = app

    token = cache_options.fetch(:token, nil)
    @ipinfo = IPinfo::create(@token, cache_options)
    @filter = cache_options.fetch(:filter, nil)
  end

  def call(env)
    env["called"] = "yes"
    request = Rack::Request.new(env)

    if !@filter.nil?
      filtered = @filter.call(request)
    else
      filtered = is_bot(request)
    end

    if filtered
      env["ipinfo"] = nil
    else
      ip = request.ip
      env["ipinfo"] = @ipinfo.details(ip)
    end

    @app.call(env)
  end

  private
    def is_bot(request)
      user_agent = request.user_agent.downcase
      user_agent.include?("bot") || user_agent.include?("spider")
    end
end
