Skynet.Sprite = {
  spectrum : [
    [-0.33, -999, "rgb(0,0,255)"], // blue
    [-0.33, -0.17, "rgb(0,100,255)"], // white-blue
    [-0.17, 0.15, "rgb(0,200,255)"], // white-bluish tinge
    [0.15, 0.44, "rgb(240,230,140)"], // yellow-white
    [0.44, 0.68, "rgb(255,255,0)"], // yellow
    [0.68, 1.15, "rgb(255,165,0)"], // orange
    [1.15, 999, "rgb(255,165,0)"] // red
  ],

  bayer_table : {
    "Alp" : "α",
    "Bet" : "β",
    "Gam" : "Γ",
    "Del" : "δ",
    "Eps" : "ε",
    "Zet" : "ζ",
    "Eta" : "η",
    "The" : "Θ",
    "Iot" : "ι",
    "Kap" : "ϰ",
    "Lam" : "λ",
    "Mu" : "μ",
    "Nu" : "ν",
    "Xi" : "ξ",
    "Omi" : "ο",
    "Pi" : "π",
    "Rho" : "ρ",
    "Sig" : "Σ",
    "Tau" : "τ",
    "Ups" : "υ",
    "Phi" : "φ",
    "Chi" : "χ",
    "Psi" : "ψ",
    "Ome" : "Ω"
  },

  bayer_replace : function(string) {
    if (string == null) return "";
    for (key in this.bayer_table) {
      string = string.replace( key, this.bayer_table[key] );
    }
    return string;
  },

  color_index : function(num) {
    for (var i = 0; i < this.spectrum.length; ++i) {
      var min = this.spectrum[i][0];
      var max = this.spectrum[i][1];
      var color = this.spectrum[i][2];

      if (num >= min && num <= max) return color;
    }
    return "rgb(0,100,255)";
  },

  star : function(obj) {
    var ctx = Skynet.ctx;
    ctx.fillStyle = "rgb(255,255,255)"

    var origin = { x: Skynet.canvas.width/2, y: Skynet.canvas.height/2 }

    var x = obj.x + origin.x;
    var y = -obj.y + origin.y;

    var mag = ( (5 - Math.min(4, obj.mag)) * (3/5) );

    ctx.font = "8pt mono"; 
    if (obj.name) ctx.fillText( obj.name,x+5,y+5);

    ctx.fillStyle = this.color_index(obj.color); //"rgb(255,255,255)"
    ctx.beginPath();
    ctx.arc(x,y,mag,0,2*Math.PI,true);
    ctx.fill();

    // make it twinkle!
    /*
    if (obj.mag < 3) {
      ctx.beginPath();
      ctx.strokeStyle = this.color_index(obj.color);
      ctx.lineWidth = 0.5;
      ctx.moveTo(x + ((mag/2) - ctx.lineWidth), y - (mag*2));
      ctx.lineTo(x + ((mag/2) - ctx.lineWidth), y + (mag*2));
      ctx.closePath();
      ctx.moveTo(x - (mag*2), y + ((mag/2) - ctx.lineWidth));
      ctx.lineTo(x + (mag*2), y + ((mag/2) - ctx.lineWidth));
      ctx.closePath();
      ctx.stroke();
    }*/

  },

  crosshair : function() {
    var ctx = Skynet.ctx;
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(0, canvas.height/2);
    ctx.lineTo(canvas.width, canvas.height/2);
    ctx.lineWidth = 1;
    ctx.strokeStyle = "rgba(255,255,255,0.1)"
    ctx.closePath();
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(canvas.width/2, 0);
    ctx.lineTo(canvas.width/2, canvas.height);
    ctx.closePath()
    ctx.stroke();


    // directions
    ctx.font = "bold 12pt arial"
    ctx.fillStyle = "white"
    ctx.fillText("E", canvas.width - 20, canvas.height/2 + 6)
    ctx.fillText("W", 10, canvas.height/2 + 6)
    ctx.restore();

  }
};
