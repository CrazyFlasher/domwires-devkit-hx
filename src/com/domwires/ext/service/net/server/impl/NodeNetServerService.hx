package com.domwires.ext.service.net.server.impl;

import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import com.domwires.ext.service.net.server.INetServerService;
import js.lib.Error;
import js.node.http.ClientRequest;
import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import js.node.Http;
import js.node.net.Server;
import js.node.net.Socket;
import js.node.Net;
import js.node.url.URL;
import js.node.url.URLSearchParams;

class NodeNetServerService extends AbstractService implements INetServerService
{
    @Inject("INetServerService_enabled")
    @Optional
    private var __enabled:Bool;

    @Inject("INetServerService_httpPort")
    private var _httpPort:Int;

    @Inject("INetServerService_tcpPort")
    private var _tcpPort:Int;

    @Inject("INetServerService_httpHost")
    private var _httpHost:String;

    @Inject("INetServerService_tcpHost")
    private var _tcpHost:String;

    public var requestData(get, never):String;
    private var _requestData:String;

    private var queryParams:URLSearchParams;

    private var httpServer:js.node.http.Server;
    private var tcpServer:js.node.net.Server;

    private var isOpenedHttp:Bool = false;
    private var isOpenedTcp:Bool = false;

    private var httpReqMap:Map<String, RequestResponse> = [];
    private var tcpReqMap:Map<String, RequestResponse> = [];

    public var connectionsCount(get, never):Int;
    private var _connectionsCount:Int = 0;

    override private function init():Void
    {
        initResult(__enabled);
    }

    public function close(?type:ServerType):INetServerService
    {
        if (isOpenedHttp && httpServer != null && (type == null || type == ServerType.Http))
        {
            httpServer.close((?error:Error) ->
            {
                isOpenedHttp = false;
                dispatchMessage(NetServerServiceMessageType.HttpClosed);
            });
        }

        if (isOpenedTcp && tcpServer != null && (type == null || type == ServerType.Tcp))
        {
            tcpServer.close((?error:Error) ->
            {
                isOpenedTcp = false;
                dispatchMessage(NetServerServiceMessageType.TcpClosed);
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
            var isHttps:Bool = message.connection.encrypted;
            var requestUrl:URL = new URL(message.url, (isHttps ? "https" : "http") + "://" + _httpHost);
            var req:RequestResponse = httpReqMap.get(requestUrl.pathname);
            if (req != null)
            {
                var data:String = "";
                message.on("error", (error:Error) -> 
                {
                    trace(error);
                    response.statusCode = 400;
                    response.end();
                });
                message.on("data", (chunk:String) -> data += chunk);
                message.on("end", () ->
                {
                    _requestData = data;

                    queryParams = requestUrl.searchParams;

                    handleHttpRequest(requestUrl, message);

                    dispatchMessage(NetServerServiceMessageType.GotHttpRequest);

                    sendHttpResponse(requestUrl, response);

                    dispatchMessage(NetServerServiceMessageType.SendHttpResponse);
                });
            } else
            {
                response.statusCode = 404;
                response.end();
            }
        });

        httpServer.listen(_httpPort, _httpHost);

        isOpenedHttp = true;
    }

    private function createServerTcp():Void
    {
        tcpServer = Net.createServer((socket:Socket) ->
        {
            _connectionsCount++;

            trace("Client connected: " + _connectionsCount);

            handleClientConnected();
            
            dispatchMessage(NetServerServiceMessageType.ClientConnected);

            var received:MessageBuffer = new MessageBuffer();

            socket.on(SocketEvent.Data, (chunk:String) ->
            {
                received.push(chunk);
                while (!received.isFinished())
                {
                    var data:String = received.handleData();

                    _requestData = data;
                    
                    handleTcpData();

                    dispatchMessage(NetServerServiceMessageType.GotTcpData);
                }
            });

            socket.on(SocketEvent.End, () ->
            {
                _connectionsCount--;

                trace("Client disconnected: " + _connectionsCount);

                handleClientDisconnected();

                dispatchMessage(NetServerServiceMessageType.ClientDisconnected);
            });

            socket.on(SocketEvent.Error, (error:Error) -> trace(error));
        });

        tcpServer.on(SocketEvent.Error, (error:Error) -> trace(error));
        tcpServer.listen(_tcpPort, _tcpHost);

        isOpenedTcp = true;
    }

    private function handleClientConnected():Void
    {
        
    }

    private function handleClientDisconnected():Void
    {
        
    }

    private function handleHttpRequest(requestUrl:URL, message:IncomingMessage):Void
    {
        
    }

    private function sendHttpResponse(requestUrl:URL, response:ServerResponse):Void
    {
        response.writeHead(200, {
            "Content-Length": "0",
            "Content-Type": "text/plain; charset=utf-8"
        });
        response.end();
    }

    private function handleTcpData():Void 
    {
        
    }

    public function sendTcpData(value:RequestResponse):INetServerService 
    {
        return this;
    }

    public function startListen(request:RequestResponse):INetServerService
    {
        if (!checkEnabled())
        {
            return this;
        }

        var map:Map<String, RequestResponse> = getReqMap(request.type);
        if (!map.exists(request.id))
        {
            map.set(request.id, request);
        }

        return this;
    }

    public function stopListen(request:RequestResponse):INetServerService
    {
        if (!checkEnabled())
        {
            return this;
        }

        var map:Map<String, RequestResponse> = getReqMap(request.type);

        if (map.exists(request.id))
        {
            map.remove(request.id);
        }

        return this;
    }

    public function getQueryParam(id:String):String
    {
        if (queryParams == null) return null;

        return queryParams.get(id);
    }

    public function getPort(type:ServerType):Int
    {
        if (type == ServerType.Http)
        {
            return _httpPort;
        }

        return _tcpPort;
    }

    public function getHost(type:ServerType):String
    {
        if (type == ServerType.Http)
        {
            return _httpHost;
        }

        return _tcpHost;
    }

    public function isOpened(type:ServerType):Bool
    {
        if (type == ServerType.Http)
        {
            return isOpenedHttp;
        }

        return isOpenedTcp;
    }

    private function getReqMap(type:RequestType):Map<String, RequestResponse>
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

    private function getReqById(id:String, type:RequestType):RequestResponse
    {
        return getReqMap(type).get(id);
    }

    private function get_requestData():String
    {
        return _requestData;
    }

    private function get_connectionsCount():Int
    {
        return _connectionsCount;
    }
}

class MessageBuffer
{
    private var delimiter:String;
    private var buffer:String;

    public function new(delimiter:String = "\n")
    {
        this.delimiter = delimiter;
        this.buffer = "";
    }

    public function isFinished():Bool
    {
        if (buffer.length == 0 || buffer.indexOf(delimiter) == -1)
        {
            return true;
        }
        return false;
    }

    public function push(data:String)
    {
        buffer += data;
    }

    public function getMessage():String
    {
        final delimiterIndex = buffer.indexOf(delimiter);

        if (delimiterIndex != -1)
        {
            final message = buffer.substring(0, delimiterIndex);
            buffer = StringTools.replace(buffer, message + delimiter, "");

            return message;
        }
        return null;
    }

    public function handleData():String
    {
        return getMessage();
    }
}