require "spec_helper"

describe SlidesController do
  describe "routing" do

    it "routes to #index" do
      get("/slides").should route_to("slides#index")
    end

    it "routes to #new" do
      get("/slides/new").should route_to("slides#new")
    end

    it "routes to #show" do
      get("/slides/1").should route_to("slides#show", :id => "1")
    end

    it "routes to #edit" do
      get("/slides/1/edit").should route_to("slides#edit", :id => "1")
    end

    it "routes to #create" do
      post("/slides").should route_to("slides#create")
    end

    it "routes to #update" do
      put("/slides/1").should route_to("slides#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/slides/1").should route_to("slides#destroy", :id => "1")
    end

  end
end
