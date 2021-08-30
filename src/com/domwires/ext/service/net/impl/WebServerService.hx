package com.domwires.ext.service.net.impl;

import js.lib.Error;
import js.lib.Uint8Array;
import js.node.buffer.Buffer;
import js.node.http.ClientRequest;
import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import js.node.Http;
import js.node.net.Socket;
import js.node.Net;

class WebServerService extends AbstractService implements IWebServerService
{
    @Inject("IWebServerService_enabled") @Optional
    private var __enabled:Bool;

    @Inject("IWebServerService_httpPort")
    private var _httpPort:Int;

    @Inject("IWebServerService_tcpPort")
    private var _tcpPort:Int;

    private var httpServer:js.node.http.Server;
    private var tcpServer:js.node.net.Server;

    private var isOpenedHttp:Bool = false;
    private var isOpenedTcp:Bool = false;

    private var httpReqMap:Map<String, Request> = [];
    private var tcpReqMap:Map<String, Request> = [];

    override private function init():Void
    {
        initResult(__enabled);
    }

    public function close(?type:ServerType):IWebServerService
    {
        if (isOpenedHttp && httpServer != null && (type == null || type == ServerType.Http))
        {
            httpServer.close(() ->
            {
                isOpenedHttp = false;
                dispatchMessage(WebServerServiceMessageType.HttpClosed);
            });
        }

        if (isOpenedTcp && tcpServer != null && (type == null || type == ServerType.Tcp))
        {
            tcpServer.close(() ->
            {
                isOpenedTcp = false;
                dispatchMessage(WebServerServiceMessageType.TcpClosed);
            });
        }

        return this;
    }

    override public function dispose():Void
    {
        close();

        super.dispose();
    }

    override private function initSuccess():Void
    {
        super.initSuccess();

        createServerHttp();
        createServerTcp();
    }

    private function createServerHttp():Void
    {
        httpServer = Http.createServer((message:IncomingMessage, response:ServerResponse) ->
        {
//            response.writeHead(200, {'Content-Type': 'text/plain'});
//            response.end('Echo http');
            var req:Request = httpReqMap[message.url];
            if (req != null)
            {
                var chunkList:Array<Uint8Array> = [];
                message.on("data", chunk -> chunkList.push(chunk));
                message.on("end", () -> {
                    var data:Buffer = Buffer.concat(chunkList);
                    trace("Received from client in request: " + data);

                    handleRequest(req, message, data);

                    response.writeHead(200, {
                        "Content-Length": "0",
                        "Content-Type": "text/plain; charset=utf-8"
                    });
                    response.end("");
                });
            }
        });

        httpServer.listen(_httpPort, "127.0.0.1");

        isOpenedHttp = true;
    }

    private function createServerTcp():Void
    {
        tcpServer = Net.createServer((socket:Socket) ->
        {
            socket.write("Echo socket");
            socket.pipe(socket);

            dispatchMessage(WebServerServiceMessageType.ClientConnected);
        });

        tcpServer.listen(_tcpPort, "127.0.0.1");

        isOpenedTcp = true;
    }

    private function handleRequest(request:Request, message:IncomingMessage, data:Buffer):Void
    {
        dispatchMessage(WebServerServiceMessageType.GotRequest);
    }

    public function startListen(request:Request):IWebServerService
    {
        if(!checkEnabled())
        {
            return this;
        }

        var map:Map<String, Request> = getReqMap(request.type);
        if (!map.exists(request.id))
        {
            map.set(request.id, request);
        }

        return this;
    }

    public function stopListen(request:Request):IWebServerService
    {
        if(!checkEnabled())
        {
            return this;
        }

        var map:Map<String, Request> = getReqMap(request.type);

        if (map.exists(request.id))
        {
            map.remove(request.id);
        }

        return this;
    }

    public function getPort(type:ServerType):Int
    {
        if (type == ServerType.Http)
        {
            return _httpPort;
        }

        return _tcpPort;
    }

    public function getIsOpened(type:ServerType):Bool
    {
        if (type == ServerType.Http)
        {
            return isOpenedHttp;
        }

        return isOpenedTcp;
    }

    private function getReqMap(type:RequestType):Map<String, Request>
    {
        if (isHttp(type))
        {
            return httpReqMap;
        }

        return tcpReqMap;
    }

    private function isHttp(type:RequestType):Bool
    {
        return type != RequestType.Tcp;
    }

    private function isListeningRequest(id:String, type:RequestType):Bool
    {
        return getReqById(id, type) != null;
    }

    private function getReqById(id:String, type:RequestType):Request
    {
        return getReqMap(type).get(id);
    }
}
