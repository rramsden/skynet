Skynet.Util = {

  ////
  // Lookup giving an array of celestial objects
  get_star : function(id,stars) {
    for (key in stars) {
      if (stars[key].id == id) return stars[key];
    }
    return null;
  },

  julian_day : function() {
    var date = new Date()
    var local_time = date.getTime()
    var local_offset = date.getTimezoneOffset() * (60*1000)
    var utc_time = local_time + local_offset;
    var utc_date = new Date(utc_time);

    var utc_hour = utc_date.getHours();
    var utc_day = utc_date.getDate();
    var utc_month = utc_date.getMonth() + 1; // 0-11 => 1-12
    var utc_year = utc_date.getFullYear();
    var UT = utc_hour + date.getMinutes()/60 + date.getSeconds()/3600;

    if (utc_month <= 2) { utc_month = utc_month+12; utc_year = utc_year-1 } // if the month is Jan or Feb subtract one from Y, add 12 to month
    A = Math.floor(utc_year/100);
    JD =  Math.floor(365.25*( utc_year + 4716 )) + Math.floor(30.6001*(utc_month+1)) + utc_day - 13 -1524.5 + UT/24.0;
    return JD
  },

  GMST : function(jd) {
    var t_eph, ut, MJD0, MJD;

    MJD = jd - 2400000.5;
    MJD0 = Math.floor(MJD);
    ut = (MJD - MJD0)*24.0;
    t_eph  = (MJD0-51544.5)/36525.0;
    return  6.697374558 + 1.0027379093*ut + (8640184.812866 + (0.093104 - 0.0000062*t_eph)*t_eph)*t_eph/3600.0;
  },

  frac : function(X) {
    X = X - Math.floor(X);
    if (X<0) X = X + 1.0;
    return X;
  },

  LMST : function(longitude) {
    var jd = this.julian_day();
    var _GMST = this.GMST(jd);
    var _LMST =  24.0*this.frac((_GMST + longitude/15.0)/24.0);
    return _LMST;
  },

  // fit a number on a different range of numbers
  fit : function(x,min,max,a,b) {
    return (((b-a)*(x - min)) / (max - min)) + a;
  },

  unfit : function(n) {
    var range_of_stars = 1000.0*2; // distance in light years
    var range_of_circle = Skynet.radius*2;

    return n * (range_of_stars/range_of_circle);
  },

  x_rotate : function(offset) {
    var rad = offset * (Math.PI/180);
    return $M([[1,0,0],
               [0,Math.cos(rad),-Math.sin(rad)],
               [0,Math.sin(rad),Math.cos(rad)]]);
  },

  y_rotate : function(offset) {
    var rad = offset * (Math.PI/180);
    return $M([[Math.cos(rad),0,Math.sin(rad) ],
               [0,1,0],
               [-Math.sin(rad),0,Math.cos(rad)]]);
  },

  unit_circle : function(x,y,theta) {
    if (y < 0 && x > 0) { return 180 - theta }
    if (y < 0 && x < 0) { return 180 + Math.abs(theta) }
    if (y > 0 && x < 0) { return 270 + (90 - Math.abs(theta)) }
    return theta;
  },

  z_rotate : function(offset) {
    var rad = offset * (Math.PI/180);
    return $M([[Math.cos(rad), -Math.sin(rad),0],
               [Math.sin(rad),Math.cos(rad),0],
               [0,0,1]]);
  },

  click_coord : function(e) {
    var x;
    var y;
    if (e.pageX || e.pageY) { 
      x = e.pageX;
      y = e.pageY;
    }
    else { 
      x = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft; 
      y = e.clientY + document.body.scrollTop + document.documentElement.scrollTop; 
    } 
    canvas = document.getElementById("skymap");
    x -= canvas.offsetLeft;
    y -= canvas.offsetTop;
    x = x - canvas.width/2;
    y = - (y - canvas.height/2);
    return [x,y];
  }

};
