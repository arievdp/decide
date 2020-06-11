class ResultsController < ApplicationController
  require 'json'
  require 'open-uri'
  require "uri"
  require 'net/http'

  def show
    @result = Result.find(params[:id])
  end

  def create
    @result = Result.new(result_params)
    @event = Event.find(params[:event_id])
    start_at = @event.start_at.to_i
    geo_center = find_geo_center(@event)
    lat = geo_center[:latitude]
    long = geo_center[:longitude]
    # unix_start_at_with_timezone = set_timezone(lat, long, start_at)
    top_cuisine = find_top_cuisine(@event)
    yelp_results(lat, long, top_cuisine)
    @restaurant = Restaurant.last
    @result.restaurant = @restaurant
    @result.event = @event
    @result.save!
    redirect_to event_result_path(@event, @result)
  end

  def set_timezone(lat, long, start_at)
    url = URI("https://maps.googleapis.com/maps/api/timezone/json?location=#{lat},#{long}&timestamp=#{start_at}&key=#{ENV['GPLACES_KEY']}")
    api_key = "" # Placed in above URL
    response = api_call(url, api_key)
    hash = parse(response)
    (start_at + hash["dstOffset"] + hash["rawOffset"])
  end

  def restaurant_create
    @restaurant = Restaurant.new(restaurant_params)
  end

  def find_top_cuisine(event)
    # counts the user selection of cuisines and returns the most picked cuisine
    cuisine_array = []
    event.invitations.each do |i|
      cuisine_array << i.cuisine.name
    end
    cuisine_array.max_by { |i| cuisine_array.count(i) }
  end

  def find_geo_center(event)
    # accept an an array of hashes of user co-ordinates and return the geographical center
    coords_array = []
    event.invitations.each do |i|
      coords_array << { latitude: i.latitude, longitude: i.longitude }
    end
    average_geo_location(coords_array)
  end

  def average_geo_location(coords)
    return coords[0] if coords.length == 1

    x = 0.0
    y = 0.0
    z = 0.0
    coords.each do |coord|
      latitude = coord[:latitude] * Math::PI / 180
      longitude = coord[:longitude] * Math::PI / 180
      x += Math.cos(latitude) * Math.cos(longitude)
      y += Math.cos(latitude) * Math.sin(longitude)
      z += Math.sin(latitude)
    end
    total = coords.length
    x /= total
    y /= total
    z /= total
    central_longitude = Math.atan2(y, x)
    central_square_root = Math.sqrt(x * x + y * y)
    central_latitude = Math.atan2(z, central_square_root)
    { latitude: central_latitude * 180 / Math::PI, longitude: central_longitude * 180 / Math::PI }
  end

  def yelp_results(lat, long, food)
    radius = 2000
    fail_block = "22221231231212512"
    # url = URI("https://api.yelp.com/v3/businesses/search?term=#{food}&latitude=#{lat}&longitude=#{long}&radius=#{radius}&open_at=#{time}")
    url = URI("https://api.yelp.com/v3/businesses/search?term=#{food}&latitude=#{lat}&longitude=#{long}&radius=#{radius}")
    api_key = ENV["YELP_KEY"]
    response = api_call(url, api_key)
    yelp_json = parse(response)["businesses"]
    ordered_results = sort_yelp_results(yelp_json, radius)
    create_restaurant_yelp(ordered_results.first)
  end

  def sort_yelp_results(json, radius)
    json.map do |j|
      decide_rating = j["rating"] * (radius - j["distance"])
      j["decide_rating"] = decide_rating
    end
    json.sort_by { |hash| -hash['decide_rating'] }
  end

  def zomato_api_call(geo_center, cuisine)
    # search_radius = 0
    # url = URI("https://developers.zomato.com/api/v2.1/search?q=#{cuisine}&lat=#{geo_center[:latitude]}&lon=#{geo_center[:longitude]}&radius=#{search_radius}&sort=real_distance")
    # https = Net::HTTP.new(url.host, url.port)
    # https.use_ssl = true
    # request = Net::HTTP::Get.new(url)
    # request["user-key"] = ENV["ZOMATO_KEY"]
    # response = https.request(request)
    # zomato_json = JSON.parse(response.read_body)
    # raise
    # create_restaurant(zomato_json["restaurants"]["name"].first)
  end

  def create_restaurant_yelp(hash)
    new_restaurant = Restaurant.new(
      yelp_id: hash["url"],
      name: hash["name"],
      description: hash["categories"][0]["title"],
      location: hash[
        "location"]["display_address"].join(", "),
      rating: hash["rating"]
    )
    new_restaurant.save!
  end

  def create_restaurant_zomato(hash)
    new_restaurant = Restaurant.new(
      yelp_id: hash["id"],
      name: hash["name"],
      description: hash["categories"][0]["title"],
      location: hash[
        "location"]["display_address"].join(", "),
      rating: hash["rating"]
    )
    new_restaurant.save!
  end

  private

  def api_call(url, api_key)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = api_key
    https.request(request)
  end

  def parse(response)
    JSON.parse(response.read_body)
  end

  def result_params
    params.permit(:event_id)
  end
end
