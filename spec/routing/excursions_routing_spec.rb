require "spec_helper"

describe ExcursionsController do
  describe "routing" do

    it "routes to #index" do
      get("/excursions").should route_to("excursions#index")
    end

    it "routes to #new" do
      get("/excursions/new").should route_to("excursions#new")
    end

    it "routes to #show" do
      get("/excursions/1").should route_to("excursions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/excursions/1/edit").should route_to("excursions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/excursions").should route_to("excursions#create")
    end

    it "routes to #update" do
      put("/excursions/1").should route_to("excursions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/excursions/1").should route_to("excursions#destroy", :id => "1")
    end

  end
end
