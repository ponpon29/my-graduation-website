namespace :shop_photos do
  desc "既存店舗の写真を一括取得"
  task fetch: :environment do
    shops = Shop.where("photos = '[]' OR photos IS NULL")
    
    puts "=" * 50
    puts "既存店舗の写真を一括取得します"
    puts "対象店舗数: #{shops.count}件"
    puts "=" * 50
    
    success_count = 0
    error_count = 0
    
    shops.find_each.with_index(1) do |shop, index|
      if shop.place_id.blank?
        puts "[#{index}/#{shops.count}] スキップ: #{shop.name} (place_idが存在しません)"
        error_count += 1
        next
      end
      
      puts "[#{index}/#{shops.count}] 取得中: #{shop.name}"
      
      begin
        service = GooglePlacesService.new
        photo_data = service.fetch_photos(shop.place_id, max_photos: 9)
        
        if photo_data.present?
          shop.update_columns(
            photos: photo_data,
            photos_cached_at: Time.current
          )
          puts "  ✅ #{photo_data.count}枚の写真を保存しました"
          success_count += 1
        else
          puts "  ⚠️  写真が見つかりませんでした"
          error_count += 1
        end
        
        sleep 1
        
      rescue => e
        puts "  ❌ エラー: #{e.message}"
        error_count += 1
      end
    end
    
    puts "=" * 50
    puts "完了"
    puts "成功: #{success_count}件 / 失敗: #{error_count}件"
    puts "=" * 50
  end
end