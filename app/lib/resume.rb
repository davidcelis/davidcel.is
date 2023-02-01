module Resume
  DATA = YAML.load_file(Rails.root.join("db", "resume.yml"), permitted_classes: [Date]).freeze
end
