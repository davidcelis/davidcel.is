class GenerateSnapshotJob < ApplicationJob
  def perform(id)
    check_in = CheckIn.find(id)

    snapshot = Apple::MapKit::Snapshot.new(point: [check_in.place.latitude, check_in.place.longitude].join(","))
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
  end
end
