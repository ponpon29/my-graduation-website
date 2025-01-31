namespace :search_kurume_ramen do
  desc "Search ramen shops in Kurume, Chikugo, Omuta, Yanagawa"
  task :ramen => :environment do
    require 'google_places'
    require 'securerandom'
    require 'set'

    api_key = ENV['PLACES_API_KEY']
    places = GooglePlaces::Client.new(api_key)

    areas = [
      { name: '久留米市', lat: 33.3184, lng: 130.4967 },
      { name: '筑後市', lat: 33.2231, lng: 130.4414 },
      { name: '大牟田市', lat: 33.1313, lng: 130.4045 },
      { name: '柳川市', lat: 33.2333, lng: 130.3144 }  
    ]

    radius = 10000

    queries = [
      'とんこつラーメン', '豚骨ラーメン', 'ラーメン',
      '博多ラーメン', '久留米ラーメン', '長浜ラーメン',
      '熊本ラーメン', ]

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

