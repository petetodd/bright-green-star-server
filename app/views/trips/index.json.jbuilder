json.array!(@trips) do |trip|
  json.extract! trip, :id, :name, :typetrip, :content
  json.url trip_url(trip, format: :json)
end
