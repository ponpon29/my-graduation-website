require 'google_places'
require 'securerandom'
require 'set'

api_key = 

places = GooglePlaces::Client.new(api_key)

areas = [
  { name: '福岡市', lat: 33.5902, lng: 130.4017 },
  { name: '北九州市', lat: 33.8830, lng: 130.8753 },
  { name: '久留米市', lat: 33.3128, lng: 130.4420 },
  { name: '春日市', lat: 33.4785, lng: 130.4632 },
  { name: '大野城市', lat: 33.5608, lng: 130.4854 },
  { name: '糸島市', lat: 33.5744, lng: 130.0560 },
  { name: '筑紫野市', lat: 33.5249, lng: 130.5590 },
]

radius = 5000

queries = [
  'とんこつラーメン', '豚骨ラーメン', 
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

    results = places.spots(area[:lat], area[:lng], radius: radius, keyword: query, opennow: true, language: 'ja', rankby: 'prominence', types: ['restaurant'])  # ここでカテゴリ「restaurant」を指定

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

        if visited_place_ids.include?(place_id)
          puts "店舗 '#{name}' はすでに訪れています。スキップします。"
          next
        end

        puts "店名: #{name}"

        visited_place_ids.add(place_id)
      end
    end
    
    area_searched_keywords[area[:name]].add(query)
  end
end
