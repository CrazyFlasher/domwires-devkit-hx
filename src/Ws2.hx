import haxe.Timer;
import haxe.io.Bytes;
import hx.ws.Log;
import hx.ws.SocketImpl;
import hx.ws.Types.MessageType;
import hx.ws.WebSocket;
import hx.ws.WebSocketHandler;
import hx.ws.WebSocketServer;
import js.node.Http;

class Ws2
{
    static public function main()
    {
        #if js
        untyped global.WebSocket = require("ws");
        #end

        var server:js.node.http.Server = Http.createServer();

        server.listen(5000, "localhost", () -> {
            trace("Http server created");

            new Server();
            new Client();
        });
    }
}

class Client {
    public function new() {
        Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
        var ws = new WebSocket("ws://localhost:5001", false);
        Timer.delay(() -> {
            ws.open();
            ws.onopen = function() {
                ws.send("alice string");
                ws.send(Bytes.ofString("alice bytes"));
            };
            ws.onerror = (?e) -> {
                trace("error");
            };
            ws.onclose = () -> {
                trace("close");
            };
        }, 100);
    }
}

class Server {
    public function new() {
        Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
        var server = new WebSocketServer<Handler>("localhost", 5001, 10);
        server.start(() -> trace("started"));
    }
}

class Handler extends WebSocketHandler {
    public function new(s: SocketImpl) {
        super(s);
        onopen = function() {
            trace(id + ". OPEN");
        }
        onclose = function() {
            trace(id + ". CLOSE");
        }
        onmessage = function(message: MessageType) {
            switch (message) {
                case BytesMessage(content):
                    trace(content.readAllAvailableBytes());
                case StrMessage(content):
                    var str = "echo: " + content;
                    trace(str);
                    send(str);
            }
        }
        onerror = function(error) {
            trace(id + ". ERROR: " + error);
        }
    }
}