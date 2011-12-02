var Skynet = {

  canvas : null,
  ctx : null,

  starbuffer : null, // holds last fetched star data

  width : null,
  height : null,

  radius : null,
  stars : null,
  rotation : null,
  celestial_eq : null,

  longitude : null,
  latitude : null,

  zoom : 0,
  is_zoomed : false,
  last_target : null, // used when zooming in, we need to know which object to base lookups off

  init : function(stars) {
    this.stars = stars;
    this.width = $(window).width();
    this.height = $(window).height();
    this.radius = (this.height/2) - 10;
    this.latitude = 49.1577;
    this.longitude = -124.9663;
    this.celestial_eq = -(90 - this.latitude); // celestial sphere is tilted back to display current night sky based on latitude
    this.rotation = 270 - (Skynet.Util.LMST(this.longitude) * 15.0);

    $('#container').html('<canvas id="skymap" width="'+this.width+'" height="'+this.height+'"></canvas>');
    this.canvas = document.getElementById("skymap");
    this.ctx = this.canvas.getContext("2d");

    this.render(stars,this.radius);
    Skynet.Listeners.init();
  },

  where : function() {
      $.ajax({
        url: "/where",
        success: function(data) {
          console.log(data);
        }
      });
  },

  zoom : function(selected) {
    $("#back").show();
    $("#back").click(function() {
      Skynet.render(Skynet.stars);
      $(this).hide();
      return false;
    });

    var stars = this.starbuffer;
    var ctx = this.ctx;
    this.is_zoomed = true;
    this.last_target = stars[selected];

    ctx.save();
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    ///
    // Focus on object of interest
    var looking_at = Skynet.Util.get_star(selected,stars);
    var name = (looking_at.name == null) ? looking_at.bayer : looking_at.name;
    var transform = this.center(looking_at);

    ///
    // Apply a transformation to each celestial object nearby
    // to focus it into the center of view
    for (var key in stars) {
      var x = stars[key].x;
      var y = stars[key].y;
      var z = stars[key].z;
      var point = $M([[x],[y],[z]]);
      var obj = Skynet.to_obj( transform.x(point) );

      obj.name = stars[key].name;
      obj.bayer = stars[key].bayer
      obj.mag = stars[key].mag;
      obj.color = stars[key].color;
    //  obj.fit(-1000.0,1000.0,-this.radius,this.radius);

      Skynet.Sprite.star(obj);
    }
    Skynet.Sprite.crosshair();
    ctx.restore();
  },

  render : function(stars) {
    this.is_zoomed = false;
    canvas = document.getElementById("skymap");
    ctx = canvas.getContext("2d");
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    origin = { x: canvas.width/2, y: canvas.height/2 }

    ctx.save();

    Skynet.Sprite.crosshair();

    ctx.beginPath();
    ctx.arc( origin.x, origin.y, this.radius, 0, 2*Math.PI, true );
    ctx.lineWidth = 7;
    ctx.strokeStyle = "rgba(255,0,0,0.5)"
    ctx.stroke();
    ctx.fill();

    for (var key in stars) {
      var obj = this.transform( stars[key] );
      obj.name = stars[key].name;
      obj.bayer = stars[key].bayer;
      obj.mag = stars[key].mag;
      obj.color = stars[key].color;

      if (obj.z < 0) continue;

      Skynet.Sprite.star( obj );
    }
    ctx.restore();
  },

  ////
  // figures out where the nearest celestial object on the screen is
  nearest : function(x,y) {
    var distance = 9999; // inf
    var neighbour = null;
    var data = null; 
    var transform = null;

    ////
    // we've moved a star to center of view
    // which means we need a different linear transformation
    if (this.is_zoomed == true) {
      data = this.starbuffer;
      transform = function(obj) {
        var t = Skynet.center( Skynet.last_target );
        var v = $M([[obj.x],[obj.y],[obj.z]]);
        return Skynet.to_obj( t.x(v) );
      };
    } else {
      data = this.stars;
      transform = function(obj) { return Skynet.transform(obj) };
    }

    for (var key in data) {
      var obj = transform( data[key] );
      var dx = obj.x;
      var dy = obj.y;
      var dz = obj.z;

      if (dz < 0) continue;

      var dist = Math.sqrt((dx - x)*(dx - x) + (dy - y)*(dy - y));

      if (dist < distance) {
        distance = dist;
        neighbour = key;
      }
    }

    return neighbour;
  },

  transform : function(obj) {
    var x = obj.x;
    var y = obj.y;
    var z = obj.z;
    var transform = Skynet.Util.x_rotate(this.celestial_eq).x( Skynet.Util.z_rotate(this.rotation) );

    var point = $M([[x],[y],[z]]);
    var new_obj = Skynet.to_obj( transform.x(point) );
    new_obj.fit(-1000,1000,-this.radius,this.radius);
    return new_obj;
  },


  ////
  // center an object of interest, this transformation rotates
  // the celestial sphere and brings the object into center view
  center : function(obj,apply_transformation) {
    var x = obj.x;
    var y = obj.y;
    var z = obj.z;

    var theta = Skynet.Util.unit_circle( x,y, Math.asin( x / Math.sqrt(x*x + y*y) ) * (180/Math.PI) );
    var zenith = 90 - obj.dec;
    t1 = Skynet.Util.z_rotate(theta);
    t2 = Skynet.Util.x_rotate(zenith);
    t3 = Skynet.Util.z_rotate(-theta);
    t4 = Skynet.Util.z_rotate(this.rotation);

    var transform = t4.x( t3.x( t2.x( t1 ) ) );

    return transform
  },

  to_obj : function(m) {
    var xyz = m.elements;
    var x = xyz[0][0];
    var y = xyz[1][0];
    var z = xyz[2][0];
    return Skynet.object(x,y,z);
  },

  object : function(x,y,z) {
    return {'x': x, 
            'y': y, 
            'z': z,
            fit : function(min,max,a,b) {
              this.x = Skynet.Util.fit(this.x,min,max,a,b);
              this.y = Skynet.Util.fit(this.y,min,max,a,b);
              this.z = Skynet.Util.fit(this.z,min,max,a,b);
            }
    };
  }
};
