require Rails.root.join("lib/tasks/tonkotsu_helpers")

namespace :fetch_google do
  desc "大阪府全域 small-area × textsearch × 3keyword とんこつ収集（深夜営業つき）"
  task osaka_full: :environment do
    require "google_places"
    google = GooglePlaces::Client.new(ENV["PLACES_API_KEY"])

    areas = {
      "大阪駅"       => [34.7025, 135.4959],
      "梅田"         => [34.7033, 135.5001],
      "北新地"       => [34.6998, 135.4980],
      "中津"         => [34.7096, 135.4930],

      "なんば"       => [34.6633, 135.5011],
      "心斎橋"       => [34.6720, 135.5015],
      "道頓堀"       => [34.6690, 135.5010],
      "日本橋"       => [34.6660, 135.5080],

      "天王寺"       => [34.6452, 135.5139],
      "阿倍野"       => [34.6425, 135.5140],

      "京橋"         => [34.6973, 135.5357],

      "弁天町"       => [34.6695, 135.4632],
      "西九条"       => [34.6880, 135.4600],

      "江坂"         => [34.7575, 135.4962],
      "豊中"         => [34.7833, 135.4701],
      "吹田"         => [34.7599, 135.5153],
      "茨木"         => [34.8160, 135.5626],
      "高槻"         => [34.8510, 135.6171],

      "堺東"         => [34.5731, 135.4832],
      "中百舌鳥"     => [34.5533, 135.5089],
      "三国ヶ丘"     => [34.5706, 135.4956],

      "布施"         => [34.6637, 135.5612],
      "八尾"         => [34.6187, 135.6008]
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