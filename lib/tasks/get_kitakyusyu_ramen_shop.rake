namespace :search_kitakyusyu_ramen do
  desc "Search ramen shops in Kitakyushu, Iizuka, Nogata, Munakata"
  task :ramen => :environment do
    return true
    require 'google_places'
    require 'securerandom'
    require 'set'

    api_key = ENV['PLACES_API_KEY']
    places = GooglePlaces::Client.new(api_key)

    areas = [
      { name: '北九州市', lat: 33.8833, lng: 130.8751 },
      { name: '飯塚市', lat: 33.5656, lng: 130.7572 },
      { name: '直方市', lat: 33.7086, lng: 130.7350 },
      { name: '宗像市', lat: 33.8461, lng: 130.6358 }
    ]

    radius = 10000

    queries = [
      'とんこつラーメン', '豚骨ラーメン', 'ラーメン',
      '博多ラーメン', '久留米ラーメン', '長浜ラーメン',
      '熊本ラーメン'
    ]

    area_searched_keywords = {}
    visited_place_ids = Set.new

    areas.each do |area|
      area_searched_keywords[area[:name]] = Set.new

      puts "#{area[:name]}での検索を開始します..."

      queries.each do |query|
        if area_searched_keywords[area[:name]].include?(query)
          puts "キーワード '#{query}' は#{area[:name]}で既に調べました。スキップします。"
          next
        end

        puts "検索キーワード: #{query} - エリア: #{area[:name]}"

        random_param = SecureRandom.hex(10)

        results = places.spots(area[:lat], area[:lng], radius: radius, keyword: query, opennow: true, language: 'ja', rankby: 'prominence', types: ['restaurant'])

        if results.empty?
          puts "検索結果が見つかりませんでした。"
        else
          results.each do |place|
            details = places.spot(place.place_id, language: 'ja')

            name = details.name
            address = details.formatted_address
            rating = details.rating || '評価なし'
            phone = details.formatted_phone_number || '電話番号なし'
            latitude = details.lat
            longitude = details.lng
            place_id = details.place_id
            opening_hours = details.opening_hours ? details.opening_hours['weekday_text'].join(', ') : '営業時間不明'

            photo_url = nil
            if details.photos && details.photos.any?
              photo_reference = details.photos.first.photo_reference
              photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxheight=400&photoreference=#{photo_reference}&key=#{api_key}"
              puts "写真URL: #{photo_url}"
            else
              puts "写真情報がありません。"
            end

            if visited_place_ids.include?(place_id)
              puts "店舗 '#{name}' はすでに訪れています。スキップします。"
              next
            end

            begin
              Shop.create!(
                name: name,
                address: address,
                rating: rating,
                phone: phone,
                latitude: latitude,
                longitude: longitude,
                place_id: place_id,
                opening_hours: opening_hours,
                photo_url: photo_url
              )
              puts "店名: #{name} を保存しました。"
            rescue ActiveRecord::RecordInvalid => e
              puts "バリデーションエラー: #{e.record.errors.full_messages.join(', ')}"
            rescue => e
              puts "エラーが発生しました: #{e.message}"
            end

            visited_place_ids.add(place_id)
          end
        end

        area_searched_keywords[area[:name]].add(query)
      end
    end
  end
end
