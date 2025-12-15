class GooglePlacesService
  def initialize
    api_key = ENV['PLACES_API_KEY']
    
    if api_key.blank?
      Rails.logger.error("PLACES_API_KEY is not set")
      raise "Google Places API key is not configured"
    end
    
    @client = GooglePlaces::Client.new(api_key)
  end

  def fetch_photos(place_id, max_photos: 9)
    return [] if place_id.blank?

    spot = @client.spot(place_id)
    
    if spot.photos.empty?
      Rails.logger.info("No photos found for place_id: #{place_id}")
      return []
    end
    
    spot.photos.take(max_photos).map do |photo|
      {
        url: build_photo_url(photo.photo_reference),
        attribution: photo.html_attributions&.first
      }
    end
  rescue StandardError => e
    Rails.logger.error("Google Places API Error: #{e.class} - #{e.message}")
    []
  end

  private

  def build_photo_url(photo_reference, maxwidth: 400)
    "https://maps.googleapis.com/maps/api/place/photo?maxwidth=#{maxwidth}&photoreference=#{photo_reference}&key=#{ENV['PLACES_API_KEY']}"
  end
end