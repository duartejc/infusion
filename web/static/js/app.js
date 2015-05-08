import {Socket} from "phoenix"

// let socket = new Socket("/ws")
// socket.connect()
// socket.join("topic:subtopic", {}).receive("ok", chan => {
// })

class App {

  static init(){

   let socket = new Socket("/ws")
   socket.connect()
   let callback = function (chan) {
      chan.onError(function (e) {
        return console.log("something went wrong", e);
      });
      chan.onClose(function (e) {
        return console.log("channel closed", e);
      });
      chan.on("update", setTime);
   };

   let setTime = function (msg) {

     var date = new Date(msg.timestamp * 1000).toLocaleString();
     var logmsg = " - [" + date +"] "+ msg.content;

     var el = {
        div: $("<div>", {class: "oaerror "+msg.level}),
        strong: $("<strong>", {}),
        span: $("<span>", {})
    };
    el.strong.text(msg.level);
    el.span.text(logmsg);

    el.strong.appendTo(el.div);
    el.span.appendTo(el.div);
    el.div.appendTo($(".error-notice"));
   }

   socket.join("logger", {}).receive("ignore", function () {
    return console.log("auth error");
   }).receive("ok", callback).after(10000, function () {
      return console.log("Connection interruption");
   });
 }
}

$( () => App.init() )

export default App
