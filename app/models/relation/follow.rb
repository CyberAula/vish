class Relation::Follow < Relation::Single
  class << self
    def instance
      first ||
        create(:permissions => Array(Permission.find_or_create_by_action('follow')))
    end
  end
end

