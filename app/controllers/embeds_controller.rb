class EmbedsController < ApplicationController
  before_filter :authenticate_user!, :only => [ :create, :update ]
  before_filter :hack_auth, :only => :create
  include SocialStream::Controllers::Objects

  def create
    super
  end

  def update
    super
  end

  def destroy
    destroy!
  end

  private

  def hack_auth
    params["embed"] ||= {}
    params["embed"]["relation_ids"] = [Relation::Public.instance.id]
    params["embed"]["owner_id"] = current_subject.actor_id
  end
end

