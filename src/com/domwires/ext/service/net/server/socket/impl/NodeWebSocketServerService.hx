package com.domwires.ext.service.net.server.socket.impl;

import com.domwires.ext.service.net.server.socket.AbstractSocketServerService.AbstractSocketClient;
import js.node.http.IncomingMessage;
import js.npm.ws.WebSocket;
import js.npm.ws.WebSocketServer;

class NodeWebSocketServerService extends AbstractSocketServerService
{
    private var server:WebSocketServer;

    private var nextClientId:Int = 1;

    override public function close():INetServerService
    {
        if (_isOpened)
        {
            server.close();

            _isOpened = false;
            dispatchMessage(NetServerServiceMessageType.Closed);
        }

        return this;
    }

    override private function createServer():Void
    {
        server = new WebSocketServer({host: _host, port: _port}, () -> {
            trace("TCP server created: " + _host + ":" + _port);

            _isOpened = true;

            dispatchMessage(NetServerServiceMessageType.Opened);
        });

        server.on(WebSocketServerEvent.Error, (error:js.lib.Error) -> {
            trace(error);
        });

        server.on(WebSocketServerEvent.Connection, (socket:WebSocket, message:IncomingMessage) -> {
            handleClientConnected(socket);

            dispatchMessage(SocketServerServiceMessageType.ClientConnected);

            socket.on(WebSocketEvent.Message, (data:String, flag:WebSocketMessageFlag) -> {
                var reqData:RequestResponse = validateRequest(untyped socket.id, data);

                if (reqData != null)
                {
                    var req:RequestResponse = reqMap.get(reqData.id);
                    if (req != null)
                    {
                        _requestFromClientId = untyped socket.id;
                        _requestData = {id: reqData.id, data: reqData.data};

                        dispatchMessage(NetServerServiceMessageType.GotRequest);
                    } else
                    {
                        trace("Ignoring TCP request: " + reqData.id);
                    }
                }
            });

            socket.on(WebSocketEvent.Close, (code:Int, data:String) -> {
                handleClientDisconnected(socket);

                dispatchMessage(SocketServerServiceMessageType.ClientDisconnected);
            });

            socket.on(WebSocketEvent.Error, (error:js.lib.Error) -> {
                trace(error);

                handleClientDisconnected(socket);

                dispatchMessage(SocketServerServiceMessageType.ClientDisconnected);
            });
        });
    }

    private function handleClientConnected(socket:WebSocket):Void
    {
        _connectionsCount++;

        _connectedClientId = nextClientId;
        nextClientId++;

        untyped socket.id = _connectedClientId;

        var clientData:Dynamic = (factory.hasMappingForClassName("Abstract<Dynamic>", "ISocketClient_data") ?
        factory.getInstanceWithClassName("Abstract<Dynamic>", "ISocketClient_data") : {});

        clientIdMap.set(_connectedClientId, new NodeWebSocketClient(_connectedClientId, clientData, socket));

        trace("Client connected: id: " + _connectedClientId + "; Total clients: " + _connectionsCount);
    }

    private function handleClientDisconnected(socket:WebSocket):Void
    {
        _connectionsCount--;

        var clientId:Int = untyped socket.id;
        if (!clientIdMap.exists(clientId))
        {
            throw com.domwires.ext.Error.Custom("Client with id " + clientId + " doesn't exist!");
        }

        _disconnectedClientId = clientId;

        clientIdMap.remove(clientId);
        socket.terminate();

        trace("Client disconnected: id: " + clientId + "; Total clients: " + _connectionsCount);
    }
}

class NodeWebSocketClient extends AbstractSocketClient
{
    public var socket(get, never):WebSocket;
    private var _socket:WebSocket;

    public function new(id:Int, data:Dynamic, socket:WebSocket)
    {
        super(id, data);

        _socket = socket;
    }

    private function get_socket():WebSocket
    {
        return _socket;
    }

    override public function close():Void
    {
        _socket.close();
    }

    override public function write(data:String):Void
    {
        _socket.send(data);
    }
}