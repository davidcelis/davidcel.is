# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.record_timestamps = false

CDN_URL = "https://davidcelis-test.sfo3.cdn.digitaloceanspaces.com".freeze

CheckIn.includes(:place, :snapshot_attachment).find_each do |check_in|
  if check_in.slug.length > 72
    check_in.send(:generate_slug)
    check_in.save(validate: false)

    puts "Updated slug for #{check_in.slug}"
  end

  if check_in.snapshot.attached?
    puts "Skipping #{check_in.slug} because it already has a snapshot"
    next
  end

  place = check_in.place
  snapshot = Apple::MapKit::Snapshot.new(point: [place.latitude, place.longitude].join(","))
  response = HTTParty.get(snapshot.url)

  file_extension = Rack::Mime::MIME_TYPES.invert["image/png"]
  filename = "#{check_in.id}#{file_extension}"

  Tempfile.open([filename, file_extension], binmode: true) do |file|
    file.write(response.body)
    file.rewind

    check_in.snapshot.attach(
      key: "blog/#{filename}",
      io: File.open(file.path),
      filename: filename
    )
  end

  check_in.save(validate: false)

  puts "Attached snapshot for #{check_in.slug}"
end

ActiveRecord::Base.record_timestamps = true
