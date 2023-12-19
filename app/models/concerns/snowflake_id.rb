module SnowflakeID
  extend ActiveSupport::Concern

  EPOCH = 1288834974657
  NUM_RANDOM_BITS = 22

  included do
    after_initialize :generate_snowflake_id
  end

  # Generates a random, time-ordered UUID for the record
  def generate_snowflake_id(time = Time.now)
    self.id ||= SnowflakeID.generate(time)
  end

  def self.generate(time = Time.now)
    ms = ((time.to_f * 1e3) - EPOCH).round
    rand = (SecureRandom.random_number * 1e16).round
    id = ms << NUM_RANDOM_BITS

    id | rand % (2**NUM_RANDOM_BITS)
  end
end
