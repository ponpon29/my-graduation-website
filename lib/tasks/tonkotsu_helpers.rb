def non_tonkotsu?(text)
  return false if text.nil?

  ng = %w[
    家系 横浜家系 吉村家 酒井製麺
    二郎 二郎系 マシマシ ヤサイマシ
    喜多方 会津
    塩専門 塩ラーメン専門
    清湯 淡麗 醤油そば 中華そば専門
  ]

  ng.any? { |w| text.include?(w) }
end

def tonkotsu?(text)
  return false if text.nil?

  strong = %w[
    とんこつ 豚骨 白湯 白濁
    博多ラーメン 久留米ラーメン 長浜ラーメン 熊本ラーメン
  ]
  return true if strong.any? { |w| text.include?(w) }

  soft = %w[
    博多 久留米 長浜 熊本 クリーミー まろやか
    臭み パンチ コク 濃厚 こってり
    替え玉
  ]
  return true if soft.any? { |w| text.include?(w) }

  false
end

def region_score(name, address)
  text = "#{name} #{address}"

  return 1.0 if text.include?("長浜")
  return 3.0 if text.include?("久留米")
  return 2.5 if text.include?("熊本")
  return 2.0 if text.include?("博多")
  return 1.5 if text.include?("鹿児島")

  2.0
end

def word_score(name)
  score = 0.0

  light_words = ["あっさり", "ライト", "屋台", "すっきり"]
  heavy_words = ["濃厚", "こってり", "特濃", "呼び戻し", "背脂", "白湯", "骨髄"]

  light_words.each { |w| score -= 0.5 if name.include?(w) }
  heavy_words.each { |w| score += 0.7 if name.include?(w) }

  score
end

def review_score(reviews)
  text = reviews.join(" ")
  score = 0.0

  light_words = ["あっさり", "軽い", "サラッ", "あっさり目", "臭みが少ない"]
  heavy_words = ["濃厚", "ドロ", "ドロ系", "こってり", "重い", "骨の旨味", "パンチ", "臭い"]

  light_words.each { |w| score -= 0.5 if text.include?(w) }
  heavy_words.each { |w| score += 0.8 if text.include?(w) }

  score
end

def density(name:, address:, reviews: [])
  score = 0.0
  score += region_score(name, address)
  score += word_score(name)
  score += review_score(reviews)

  score = [[score, 1.0].max, 3.0].min

  case score
  when 1.0..1.6 then "light"
  when 1.7..2.3 then "normal"
  else               "rich"
  end
end

def late_night?(opening_hours)
  return false if opening_hours.nil?

  text = opening_hours.is_a?(Array) ? opening_hours.join(" ") : opening_hours.to_s

  return true if text.include?("24時間") || text.include?("24:00")

  times = text.scan(/(?:翌)?\d{1,2}:\d{2}/)

  times.each do |t|
    hour = t.gsub("翌", "").split(":").first.to_i

    return true if hour.between?(0, 5)
  end

  false
end