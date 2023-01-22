module Resume
  DATA = YAML.load_file(Rails.root.join("db", "resume.yml")).freeze
end
