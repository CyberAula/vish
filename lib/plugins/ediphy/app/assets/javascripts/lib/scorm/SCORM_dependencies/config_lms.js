var LMS_CONFIG = {
  debug: true,
  debug_scorm_player: false,
  scorm2004: {
    learner_preference: {
      _children: "audio_level,language,delivery_speed,audio_captioning,difficulty",
      difficulty: "random"
    }
  },
  scorm12: {
    student_preference: {
      _children: "audio,language,speed,text,difficulty",
      difficulty: "random"
    }
  }
};

var processConfig = (function(){
  if((LMS_CONFIG.scorm2004) && (LMS_CONFIG.scorm2004.learner_preference)){
    if(LMS_CONFIG.scorm2004.learner_preference.difficulty === "random"){
      LMS_CONFIG.scorm2004.learner_preference.difficulty = parseInt(Math.random() * 10, 10).toString();
    }
  }
  if((LMS_CONFIG.scorm12) && (LMS_CONFIG.scorm12.student_preference)){
    if(LMS_CONFIG.scorm12.student_preference.difficulty === "random"){
      LMS_CONFIG.scorm12.student_preference.difficulty = parseInt(Math.random() * 10, 10).toString();
    }
  }
})();