class EdiphyExercisesController < ApplicationController

 def xml
    ediphy_document = EdiphyExercise.find(params[:id])
    render :xml => ediphy_document.xml
  end

  def update_xml
    ediphy_document = EdiphyExercise.find(params[:id])
    ediphy_document.xml = params[:xml]
    ediphy_document.save!
    render :xml => ediphy_document.xml
  end

end
