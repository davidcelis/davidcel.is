# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

MediaAttachment.includes(file_attachment: :blob, webp_variant_attachment: :blob).find_each do |media_attachment|
  next if media_attachment.webp_variant.attached?
  next unless media_attachment.image?

  filename = File.basename(media_attachment.file.blob.filename.to_s, ".*")

  media_attachment.file.blob.open do |file|
    webp = ImageProcessing::Vips
      .source(file)
      .convert("webp")
      .call

    media_attachment.webp_variant.attach(
      key: "blog/#{media_attachment.id}.webp",
      io: File.open(webp.path),
      filename: "#{filename}.webp"
    )

    puts "Created webp variant: blog/#{media_attachment.id}.webp"
  end
end

CheckIn.includes(snapshot_attachment: :blob, webp_snapshot_attachment: :blob).find_each do |check_in|
  next if check_in.webp_snapshot.attached?

  check_in.snapshot.blob.open do |file|
    webp = ImageProcessing::Vips
      .source(file)
      .convert("webp")
      .call

    check_in.webp_snapshot.attach(
      key: "blog/snapshots/#{check_in.id}.webp",
      io: File.open(webp.path),
      filename: "#{check_in.id}.webp"
    )

    puts "Created webp snapshot: blog/snapshots/#{check_in.id}.webp"
  end
end
