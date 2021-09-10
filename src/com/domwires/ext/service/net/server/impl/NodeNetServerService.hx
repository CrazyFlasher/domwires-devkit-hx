package com.domwires.ext.service.net.server.impl;

import com.domwires.core.common.AbstractDisposable;
import com.domwires.core.common.IDisposable;
import com.domwires.core.factory.AppFactory;
import haxe.Json;
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

    public var requestData(get, never):RequestResponse;
    private var _requestData:RequestResponse;

    private var queryParams:URLSearchParams;

    private var httpServer:js.node.http.Server;
    private var tcpServer:js.node.net.Server;

    public var isOpened(get, never):Bool;
    private var _isOpened:Bool = false;

    private var httpReqMap:Map<String, RequestResponse> = [];
    private var tcpReqMap:Map<String, RequestResponse> = [];

    public var connectionsCount(get, never):Int;
    private var _connectionsCount:Int = 0;

    public var connectedClientId(get, never):Int;
    private var _connectedClientId:Int;

    public var disconnectedClientId(get, never):Int;
    private var _disconnectedClientId:Int;

    private var clientIdMap:Map<Int, SocketClient> = [];

    private var nextClientId:Int = 1;

    override private function init():Void
    {
        if (factory == null)
        {
            factory = new AppFactory();
        }

        initResult(__enabled);
    }

    public function close():INetServerService
    {
        if (_isOpened)
        {
            httpServer.close((?error:Error) -> {
                tcpServer.close((?error:Error) -> {
                    _isOpened = false;
                    dispatchMessage(NetServerServiceMessageType.Closed);
                });
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
    }

    private function createServerHttp():Void
    {
        httpServer = Http.createServer((message:IncomingMessage, response:ServerResponse) -> {
            var isHttps:Bool = message.connection.encrypted;
            var requestUrl:URL = new URL(message.url, (isHttps ? "https" : "http") + "://" + _httpHost);
            var req:RequestResponse = httpReqMap.get(requestUrl.pathname);
            if (req != null)
            {
                var data:String = "";
                message.on("error", (error:Error) -> {
                    trace(error);
                    response.statusCode = 400;
                    response.end();
                });
                message.on("data", (chunk:String) -> data += chunk);
                message.on("end", () -> {
                    _requestData = {id: requestUrl.pathname, data: data};

                    queryParams = requestUrl.searchParams;

                    handleHttpRequest(message);

                    dispatchMessage(NetServerServiceMessageType.GotHttpRequest);

                    sendHttpResponse(response);

                    dispatchMessage(NetServerServiceMessageType.SendHttpResponse);
                });
            } else
            {
                response.statusCode = 404;
                response.end();
            }
        });

        httpServer.listen(_httpPort, _httpHost, () -> {
            trace("HTTP server created: " + _httpHost + ":" + _httpPort);

            createServerTcp();
        });
    }

    private function createServerTcp():Void
    {
        tcpServer = Net.createServer((socket:Socket) -> {
            handleClientConnected(socket);
            
            dispatchMessage(NetServerServiceMessageType.ClientConnected);

            var received:MessageBuffer = new MessageBuffer();

            socket.on(SocketEvent.Data, (chunk:String) -> {
                received.push(chunk);
                while (!received.isFinished())
                {
                    var data:String = received.handleData();
                    _requestData = null;

                    var reqData:RequestResponse = validateRequest(socket, data);

                    if (reqData != null)
                    {
                        var req:RequestResponse = tcpReqMap.get(reqData.id);
                        if (req != null)
                        {
                            _requestData = {id: reqData.id, data: reqData.data};

                            handleTcpRequest(untyped socket.id);

                            dispatchMessage(NetServerServiceMessageType.GotTcpRequest);
                        } else
                        {
                            trace("Ignoring TCP request: " + reqData.id);
                        }
                    }
                }
            });

            socket.on(SocketEvent.End, () -> {
                handleClientDisconnected(socket);

                dispatchMessage(NetServerServiceMessageType.ClientDisconnected);
            });

            socket.on(SocketEvent.Error, (error:Error) -> {
                trace(error);

                handleSocketConnectionLost(socket);

                dispatchMessage(NetServerServiceMessageType.ClientDisconnected);
            });
        });

        tcpServer.on(SocketEvent.Error, (error:Error) -> {
            trace(error);
        });

        tcpServer.listen(_tcpPort, _tcpHost, () -> {
            trace("TCP server created: " + _tcpHost + ":" + _tcpPort);

            _isOpened = true;

            dispatchMessage(NetServerServiceMessageType.Opened);
        });
    }

    private function handleSocketConnectionLost(socket:Socket):Void
    {
        dispatchMessage(NetServerServiceMessageType.ClientDisconnected);
    }

    private function validateRequest(socket:Socket, data:String):RequestResponse
    {
        var reqData:RequestResponse;

        try
        {
            reqData = Json.parse(data);
        } catch (e:Error)
        {
            clientError("Request should be a JSON string: " + data, socket);

            return null;
        }

        if (reqData.id == null)
        {
            clientError("Request Json should contain \"id\" field!: " + data, socket);

            return null;
        }

        return reqData;
    }

    private function handleClientConnected(socket:Socket):Void
    {
        _connectionsCount++;

        _connectedClientId = nextClientId;
        nextClientId++;

        untyped socket.id = _connectedClientId;

        factory.mapClassNameToValue("js.node.net.Socket", socket, "SocketClient_socket");
        factory.mapClassNameToValue("Int", _connectedClientId, "SocketClient_id");

        clientIdMap.set(_connectedClientId, factory.getInstance(SocketClient));

        factory.unmapClassName("Int", "SocketClient_id");
        factory.unmap(js.node.net.Socket, "SocketClient_socket");

        trace("Client connected: id: " + _connectedClientId + "; Total clients: " + _connectionsCount);
    }

    private function handleClientDisconnected(socket:Socket):Void
    {
        _connectionsCount--;

        var clientId:Int = untyped socket.id;
        if (!clientIdMap.exists(clientId))
        {
            throw haxe.io.Error.Custom("Client with id " + clientId + " doesn't exist!");
        }

        _disconnectedClientId = clientId;

        clientIdMap.remove(clientId);
        socket.destroy();

        trace("Client disconnected: id: " + clientId + "; Total clients: " + _connectionsCount);
    }

    private function handleHttpRequest(message:IncomingMessage):Void
    {
        
    }

    private function sendHttpResponse(response:ServerResponse):Void
    {
        response.writeHead(200, {
            "Content-Length": "0",
            "Content-Type": "text/plain; charset=utf-8"
        });
        response.end();
    }

    private function handleTcpRequest(clientId:Int):Void
    {
    }

    public function sendTcpResponse(clientId:Int, response:RequestResponse):INetServerService
    {
        if (!clientIdMap.exists(clientId))
        {
            throw haxe.io.Error.Custom("Client with id " + clientId + " doesn't exist!");
        }

        clientIdMap.get(clientId).socket.write(Json.stringify(response) + "\n");

        return this;
    }

    public function disconnectClient(clientId:Int):INetServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        if (!clientIdMap.exists(clientId))
        {
            trace("Cannot disconnect client. Not found: " + clientId);

            return this;
        }

        clientIdMap.get(clientId).socket.end();

        return this;
    }

    public function disconnectAllClients():INetServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        for (client in clientIdMap.iterator())
        {
            client.socket.end();
        }

        return this;
    }

    public function startListen(request:RequestResponse, type:RequestType):INetServerService
    {
        if (!checkEnabled())
        {
            return this;
        }

        var map:Map<String, RequestResponse> = getReqMap(type);
        if (!map.exists(request.id))
        {
            map.set(request.id, request);
        }

        return this;
    }

    public function stopListen(request:RequestResponse, type:RequestType):INetServerService
    {
        if (!checkEnabled())
        {
            return this;
        }

        var map:Map<String, RequestResponse> = getReqMap(type);

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

    private function get_requestData():RequestResponse
    {
        return _requestData;
    }

    private function get_connectionsCount():Int
    {
        return _connectionsCount;
    }

    private function clientError(message:String, ?socket:Socket):Void
    {
        trace("Client Error: " + message);

        if (socket != null)
        {
            socket.end();
        }
    }

    private function get_isOpened():Bool
    {
        return _isOpened;
    }

    private function get_disconnectedClientId():Int
    {
        return _disconnectedClientId;
    }

    private function get_connectedClientId():Int
    {
        return _connectedClientId;
    }

    private function checkIsOpened():Bool
    {
        if (!_isOpened)
        {
            trace("Server is not opened!");

            return false;
        }

        return true;
    }
}

class SocketClient extends AbstractDisposable
{
    public var socket(get, never):Socket;

    @Inject("SocketClient_socket")
    private var _socket:Socket;

    public var id(get, never):Int;

    @Inject("SocketClient_id")
    private var _id:Int;

    private function get_socket():Socket
    {
        return _socket;
    }

    private function get_id():Int 
    {
        return _id;
    }
}