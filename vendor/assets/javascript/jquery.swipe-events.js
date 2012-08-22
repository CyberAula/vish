(function($) { 
  $.fn.swipeEvents = function() {
    return this.each(function() {
      
      var startX,
          startY,
          $this = $(this);
      
      $this.bind('touchstart', touchstart);
      
      function touchstart(event) {
        var touches = event.originalEvent.touches;
        if (touches && touches.length) {
          startX = touches[0].pageX;
          startY = touches[0].pageY;
          $this.bind('touchmove', touchmove);
        }
        event.preventDefault();
      }
      
      function touchmove(event) {
        var touches = event.originalEvent.touches;
        if (touches && touches.length) {
          var deltaX = startX - touches[0].pageX;
          var deltaY = startY - touches[0].pageY;
          
          if (deltaX >= 50) {
            $this.trigger("swipeLeft");
          }
          if (deltaX <= -50) {
            $this.trigger("swipeRight");
          }
          if (deltaY >= 50) {
            $this.trigger("swipeUp");
          }
          if (deltaY <= -50) {
            $this.trigger("swipeDown");
          }
          if (Math.abs(deltaX) >= 50 || Math.abs(deltaY) >= 50) {
            $this.unbind('touchmove', touchmove);
          }
        }
        event.preventDefault();
      }
      
    });
  };
})(jQuery);
