# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.record_timestamps = false

CDN_URL = "https://davidcelis-test.sfo3.cdn.digitaloceanspaces.com".freeze

PLACES = {}

check_ins = HTTParty.get("#{CDN_URL}/check_ins.json")
check_ins.each do |data|
  ActiveRecord::Base.transaction do
    # First, create the place
    place_id = data.dig("venue", "id")
    place = PLACES[place_id] ||= begin
      venue = data["venue"]
      place = Place.new(
        name: venue["name"],
        coordinates: [venue.dig("location", "lng"), venue.dig("location", "lat")]
      )

      place.created_at = place.updated_at = Time.at(venue["createdAt"])
      place.tap(&:save!)
    end

    check_in = CheckIn.new(
      content: data.fetch("shout", ""),
      place: place
    )

    check_in.created_at = check_in.updated_at = Time.at(data["createdAt"])
    check_in.id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{check_in.created_at}')")

    if check_in.save
      puts "Saved check-in #{data["id"]} at #{place.name}"
    else
      puts "Error saving check-in #{data["id"]}: #{check_in.errors.full_messages.to_sentence}"
      next
    end

    data.dig("photos", "items").each do |photo|
      media_attachment = check_in.media_attachments.new
      media_attachment.created_at = media_attachment.updated_at = check_in.created_at
      media_attachment.id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{check_in.created_at}')")

      file_url = [photo["prefix"], photo["width"], "x", photo["height"], photo["suffix"]].join
      response = HTTParty.get(file_url)
      raise "Error downloading #{file_url}: #{response.code}" if response.code >= 400

      file_extension = File.extname(file_url)
      filename = "#{media_attachment.id}#{file_extension}"

      Tempfile.open([filename, file_extension], binmode: true) do |file|
        file.write(response.body)
        file.rewind

        media_attachment.file.attach(
          key: "blog/#{filename}",
          io: File.open(file.path),
          filename: filename
        )

        media_attachment.save!
      end
    end
  end
end

ActiveRecord::Base.record_timestamps = true
