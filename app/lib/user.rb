class User
  attr_reader :id, :username

  def initialize(id:, username:)
    @id = id
    @username = username
  end
end
