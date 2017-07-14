class DaliExercisesController < ApplicationController

 def xml
    dali_exercise = DaliExercise.find(params[:id])
    render :xml => dali_exercise.xml
  end

  def update_xml
    dali_exercise = DaliExercise.find(params[:id])
    dali_exercise.xml = params[:xml]
    dali_exercise.save!
    render :xml => dali_exercise.xml
  end

end
