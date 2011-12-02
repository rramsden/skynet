var DEBUG = {
  funs : [],

  init : function() {
    setInterval("DEBUG.draw()",1000);
  },

  add : function(fun) {
    this.funs.push(fun);
  },

  draw : function() {
    var ctx = document.getElementById("skymap").getContext("2d");

    ctx.save();
    ctx.font = "8pt Arial";
    ctx.fillStyle = "rgba(255,255,255,0.8)";
    ctx.fillText("Hello World",0,20);
    ctx.restore();
  }
}
