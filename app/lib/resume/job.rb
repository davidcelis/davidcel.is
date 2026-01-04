class Resume::Job
  include ActiveModel::API

  attr_accessor :name, :position, :url, :startDate, :endDate, :summary
  alias_attribute :start_date, :startDate
  alias_attribute :end_date, :endDate

  cattr_accessor :all, instance_accessor: false

  self.all = Resume::DATA["work"].map do |job|
    new(job).tap { |j| j.summary.squish! }
  end

  extend Enumerable

  class << self
    delegate :each, to: :all
  end

  def image
    @image ||= "#{name.parameterize}.png"
  end
end
