require "net/http"
require "json"
require "uri"
require "set"

module FetchGooglePlacesHelpers
  module_function

  def offset_points(lat, lng, meters: 1500)
    lat_deg = meters / 111_000.0
    lng_deg = meters / (111_000.0 * Math.cos(lat * Math::PI / 180.0))
    [
      [lat, lng],
      [lat + lat_deg, lng],
      [lat - lat_deg, lng],
      [lat, lng + lng_deg],
      [lat, lng - lng_deg]
    ]
  end

  def fetch_nearby_all(api_key:, lat:, lng:, radius:, keyword:)
    results = []
    page_token = nil

    3.times do
      url =
        if page_token
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=#{page_token}&key=#{api_key}&language=ja"
        else
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lng}&radius=#{radius}&keyword=#{URI.encode_www_form_component(keyword)}&key=#{api_key}&language=ja"
        end

      json = JSON.parse(Net::HTTP.get(URI(url)))
      results.concat(json["results"] || [])

      page_token = json["next_page_token"]
      break unless page_token
      sleep 2
    end

    results
  end

  def fetch_text_all(api_key:, query:)
    results = []
    page_token = nil

    3.times do
      url =
        if page_token
          "https://maps.googleapis.com/maps/api/place/textsearch/json?pagetoken=#{page_token}&key=#{api_key}&language=ja"
        else
          "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{URI.encode_www_form_component(query)}&key=#{api_key}&language=ja"
        end

      json = JSON.parse(Net::HTTP.get(URI(url)))
      results.concat(json["results"] || [])

      page_token = json["next_page_token"]
      break unless page_token
      sleep 2
    end

    results
  end

  def fetch_details(api_key:, place_id:)
    fields = "name,formatted_address,geometry,formatted_phone_number,place_id,rating,opening_hours,photos,reviews"
    url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=#{place_id}&key=#{api_key}&language=ja&fields=#{fields}"
    json = JSON.parse(Net::HTTP.get(URI(url)))
    json["result"]
  end

  def photo_url_from(place, api_key)
    return nil unless place["photos"]&.any?
    ref = place["photos"].first["photo_reference"]
    "https://maps.googleapis.com/maps/api/place/photo?maxheight=600&photoreference=#{ref}&key=#{api_key}"
  end

  def save_place!(api_key:, place_id:)
    place = fetch_details(api_key: api_key, place_id: place_id)
    return :skip unless place && place["name"]

    name    = place["name"]
    address = place["formatted_address"].to_s
    reviews = (place["reviews"] || []).map { |r| r["text"].to_s }

    text = [name, address, reviews.join(" ")].join(" ")
    return :skip if TonkotsuHelpers.non_tonkotsu?(text)
    return :skip unless TonkotsuHelpers.tonkotsu?(text)

    density_result = TonkotsuHelpers.density(name: name, address: address, reviews: reviews)
    opening_hours_str = place.dig("opening_hours", "weekday_text")&.join(", ")

    Shop.create!(
      name: name,
      address: address,
      latitude: place.dig("geometry", "location", "lat"),
      longitude: place.dig("geometry", "location", "lng"),
      phone: place["formatted_phone_number"],
      place_id: place_id,
      rating: place["rating"],
      opening_hours: opening_hours_str,
      photo_url: photo_url_from(place, api_key),
      density: density_result
    )

    [:saved, name, density_result]
  rescue => e
    [:error, e.message]
  end

  def run!(api_key:, areas:, keywords:, radius: 3000, meters: 1500, title: nil)
    raise "PLACES_API_KEY is missing" if api_key.blank?

    puts "\n🚀 開始：#{title}" if title
    seen = Set.new(Shop.pluck(:place_id))

    areas.each do |area_name, (base_lat, base_lng)|
      puts "\n=== 🏙️ #{area_name} ==="
      scan_points = offset_points(base_lat, base_lng, meters: meters)

      keywords.each do |kw|
        puts " → keyword: #{kw}"

        scan_points.each_with_index do |(lat, lng), idx|
          nearby = fetch_nearby_all(api_key: api_key, lat: lat, lng: lng, radius: radius, keyword: kw)
          puts "   → nearby[p#{idx}] #{nearby.size}件 (#{lat},#{lng})"

          nearby.each do |hit|
            place_id = hit["place_id"]
            next if place_id.blank?
            next if seen.include?(place_id)
            seen.add(place_id)

            result = save_place!(api_key: api_key, place_id: place_id)
            if result.is_a?(Array) && result[0] == :saved
              puts "     ✔ 保存: #{result[1]} (density=#{result[2]})"
            elsif result.is_a?(Array) && result[0] == :error
              puts "     ⚠ nearby保存エラー: #{result[1]}"
            end
          end
        end

        ts = fetch_text_all(api_key: api_key, query: "#{area_name} #{kw}")
        puts "   → textsearch: #{ts.size}件"

        ts.each do |hit|
          place_id = hit["place_id"]
          next if place_id.blank?
          next if seen.include?(place_id)
          seen.add(place_id)

          result = save_place!(api_key: api_key, place_id: place_id)
          if result.is_a?(Array) && result[0] == :saved
            puts "     ✔ TS保存: #{result[1]} (density=#{result[2]})"
          elsif result.is_a?(Array) && result[0] == :error
            puts "     ⚠ TS保存エラー: #{result[1]}"
          end
        end
      end
    end

    puts "\n🎉 完了：#{title}" if title
  end
end
