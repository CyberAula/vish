module Drafts
  module ActivityObject
    extend ActiveSupport::Concern

    included do
      after_update :create_update_activity

      # TODO: this works but is rather ugly: they are in the "included" block because we want to re-define them
      def create_post_activity
        unless object.respond_to? :draft and object.draft
          self.notified_after_draft = true
          save!
          create_activity "post"
        end
      end

      def create_update_activity
        return if object.nil? or object.acts_as_actor?
        if object.respond_to? :draft and (not object.draft) and (not self.notified_after_draft)
          self.notified_after_draft = true
          save!
          create_activity "post"
        end
      end
    end
  end
end

