Skynet.Listeners = {
  init : function() {
    this.registerClickZoom();
    this.registerSmartPhoneFlip();
    this.registerKeyMovement();
    this.registerWhere();
  },

  registerClickZoom : function() {
    $(window).click(function(e) {
      var coords = Skynet.Util.click_coord(e);
      var x = coords[0];
      var y = coords[1];
      console.log("clicked: " + coords);

      var nearest = Skynet.nearest(x,y);

      $.ajax({
        url: "/starmap/" + nearest,
        success: function(data) {
          Skynet.starbuffer = data;

          if (Skynet.last_target && nearest == Skynet.last_target.id) { 
            var ra = Math.round(Skynet.last_target.ra*Math.pow(10,4))/Math.pow(10,4);
            var dec = Math.round(Skynet.last_target.dec*Math.pow(10,4))/Math.pow(10,4);
            var name = (Skynet.last_target.name != null) ? Skynet.last_target.name : Skynet.Sprite.bayer_replace( Skynet.last_target.bayer );
            var res = confirm("GOTO " + name + "\nRA,DEC: " + ra + "," + dec);
            if (res) {
            }
          }

          Skynet.zoom(nearest);
        }
      });
    });
  },

  registerWhere : function() {
    setInterval("Skynet.where()", 1000);
  },

  registerSmartPhoneFlip : function() {
    var supportsOrientationChange = "onorientationchange" in window,
      orientationEvent = supportsOrientationChange ? "orientationchange" : "resize";

    window.addEventListener(orientationEvent, function() {
      if (window.orientation != 0 && window.orientation != undefined) {
        Skynet.radius = ($(window).height())/2 - 10;
        Skynet.render(stars);
      }
    }, false);
  },

  registerKeyMovement : function() {
    $(window).keydown(function(e) {
      keycode = e.keyCode;

      if(keycode == 38) {
        Skynet.celestial_eq = (Skynet.celestial_eq + 3) % 360;
      }
      if(keycode == 40) {
        Skynet.celestial_eq = (Skynet.celestial_eq - 3) % 360;
      }
      if(keycode == 39) {
        Skynet.rotation = (Skynet.rotation + 3) % 360;
      }
      if(keycode == 37) {
        Skynet.rotation = (Skynet.rotation - 3) % 360;
      }
      Skynet.render(stars, Skynet.radius);
    });
  }
}
