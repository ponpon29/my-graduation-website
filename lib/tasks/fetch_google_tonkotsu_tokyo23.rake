require Rails.root.join("lib/tasks/tonkotsu_helpers")

namespace :fetch_google do
  desc "東京23区 small-area × textsearch × 3keyword とんこつ収集（深夜営業つき）"
  task tokyo23_full: :environment do
    require "google_places"
    google = GooglePlaces::Client.new(ENV["PLACES_API_KEY"])

    areas = {
      "千代田区" => [35.6940, 139.7530],
      "中央区"   => [35.6702, 139.7720],
      "港区"     => [35.6581, 139.7516],
      "新宿区"   => [35.6938, 139.7034],
      "文京区"   => [35.7080, 139.7528],
      "台東区"   => [35.7121, 139.7808],
      "墨田区"   => [35.7100, 139.8014],
      "江東区"   => [35.6730, 139.8174],
      "品川区"   => [35.6093, 139.7300],
      "目黒区"   => [35.6411, 139.6980],
      "大田区"   => [35.5614, 139.7160],
      "世田谷区" => [35.6467, 139.6530],
      "渋谷区"   => [35.6616, 139.7036],
      "中野区"   => [35.7074, 139.6639],
      "杉並区"   => [35.6995, 139.6363],
      "豊島区"   => [35.7289, 139.7101],
      "北区"     => [35.7528, 139.7337],
      "荒川区"   => [35.7365, 139.7839],
      "板橋区"   => [35.7517, 139.7090],
      "練馬区"   => [35.7356, 139.6517],
      "足立区"   => [35.7751, 139.8045],
      "葛飾区"   => [35.7430, 139.8470],
      "江戸川区" => [35.7063, 139.8688]
    }

    keywords = ["ラーメン", "豚骨", "とんこつ", "博多ラーメン"]

    areas.each do |area, (lat, lng)|
      puts "\n=== 🏙️ #{area} ==="

      keywords.each do |kw|
        puts " → keyword: #{kw}"

        begin
          spots = google.spots(lat, lng, radius: 3000, language: "ja", keyword: kw)
        rescue => e
          puts " × nearby失敗: #{e.message}"
          next
        end

        puts "   → nearby: #{spots.size}件"

        spots.each do |hit|
          begin
            place = google.spot(hit.place_id, language: "ja")
            next unless place&.name

            text = [
              place.name,
              place.formatted_address,
              place.reviews&.map(&:text)&.join(" ")
            ].join(" ")

            next if non_tonkotsu?(text)
            next unless tonkotsu?(text)
            next if Shop.exists?(place_id: place.place_id)

            photo_url = nil
            if place.photos&.any?
              ref = place.photos.first.photo_reference
              photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxheight=600&photoreference=#{ref}&key=#{ENV['PLACES_API_KEY']}"
            end

            density_result = density(
              name: place.name,
              address: place.formatted_address,
              reviews: place.reviews&.map(&:text) || []
            )

            late_flag = late_night?(place.opening_hours ? place.opening_hours["weekday_text"] : nil)

            Shop.create!(
              name: place.name,
              address: place.formatted_address,
              latitude: place.lat,
              longitude: place.lng,
              phone: place.formatted_phone_number,
              place_id: place.place_id,
              rating: place.rating,
              opening_hours: place.opening_hours ? place.opening_hours["weekday_text"].join(", ") : nil,
              photo_url: photo_url,
              density: density_result,
              late_night: late_flag
            )

            puts "     ✔ 保存: #{place.name} (深夜=#{late_flag}, density=#{density_result})"
          rescue => e
            puts "     ⚠ nearby保存エラー: #{e.message}"
          end
        end

        begin
          ts = google.spots_by_query("#{area} #{kw}")
        rescue => e
          puts " × textsearch失敗: #{e.message}"
          next
        end

        puts "   → textsearch: #{ts.size}件"

        ts.each do |hit|
          begin
            place = google.spot(hit.place_id, language: "ja")
            next unless place&.name
            next if Shop.exists?(place_id: place.place_id)

            text = [
              place.name,
              place.formatted_address,
              place.reviews&.map(&:text)&.join(" ")
            ].join(" ")

            next if non_tonkotsu?(text)
            next unless tonkotsu?(text)

            photo_url = nil
            if place.photos&.any?
              ref = place.photos.first.photo_reference
              photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxheight=600&photoreference=#{ref}&key=#{ENV['PLACES_API_KEY']}"
            end

            density_result = density(
              name: place.name,
              address: place.formatted_address,
              reviews: place.reviews&.map(&:text) || []
            )

            late_flag = late_night?(place.opening_hours ? place.opening_hours["weekday_text"] : nil)

            Shop.create!(
              name: place.name,
              address: place.formatted_address,
              latitude: place.lat,
              longitude: place.lng,
              phone: place.formatted_phone_number,
              place_id: place.place_id,
              rating: place.rating,
              opening_hours: place.opening_hours ? place.opening_hours["weekday_text"].join(", ") : nil,
              photo_url: photo_url,
              density: density_result,
              late_night: late_flag
            )

            puts "     ✔ TS保存: #{place.name} (深夜=#{late_flag})"
          rescue => e
            puts "     ⚠ TS保存エラー: #{e.message}"
          end
        end

      end
    end

    puts "\n🎉 完了：大阪府 全域 small-area × textsearch"
  end
end