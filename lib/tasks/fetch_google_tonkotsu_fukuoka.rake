require Rails.root.join("lib/tasks/tonkotsu_helpers")

namespace :fetch_google do
  desc "福岡県全域 small-area × textsearch × keyword とんこつ収集（深夜営業付き）"
  task fukuoka_all: :environment do
    require "google_places"
    google = GooglePlaces::Client.new(ENV["PLACES_API_KEY"])

    areas = {
      "博多駅前" => [33.5902, 130.4204], "祇園" => [33.5954, 130.4131],
      "中洲" => [33.5920, 130.4087], "住吉" => [33.5836, 130.4211],
      "美野島" => [33.5726, 130.4276], "吉塚" => [33.6100, 130.4250],
      "東比恵" => [33.5775, 130.4410], "千代" => [33.6040, 130.4170],

      "天神" => [33.5901, 130.4010], "大名" => [33.5860, 130.3930],
      "赤坂" => [33.5890, 130.3850], "薬院" => [33.5782, 130.4035],
      "平尾" => [33.5707, 130.4060],

      "小倉駅前" => [33.8860, 130.8820], "黒崎" => [33.8680, 130.7610],

      "久留米中心" => [33.3193, 130.5083], "六ツ門" => [33.3100, 130.5100],
      "合川" => [33.3270, 130.5210],

      "大牟田中心" => [33.0283, 130.4462], "柳川中心" => [33.1631, 130.4057],

      "八女中心" => [33.2117, 130.5574], "筑後中心" => [33.2127, 130.4964],
      "宗像中心" => [33.8050, 130.5400], "福津中心" => [33.7650, 130.4886],
      "糸島中心" => [33.5744, 130.0560], "行橋中心" => [33.7258, 130.9781],
      "豊前中心" => [33.6114, 131.1389]
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