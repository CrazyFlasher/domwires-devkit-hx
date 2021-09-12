package com.domwires.ext.service.net.server.socket.impl;

import com.domwires.core.common.AbstractDisposable;
import com.domwires.ext.service.net.server.INetServerService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import haxe.Json;
import js.lib.Error;
import js.node.http.ClientRequest;
import js.node.net.Server;
import js.node.net.Socket;
import js.node.Net;

class NodeSocketServerService extends AbstractNetServerService implements ISocketServerService
{
    @Inject("ISocketServerService_enabled")
    @Optional
    private var __enabled:Bool;

    @Inject("ISocketServerService_port")
    private var _port:Int;

    @Inject("ISocketServerService_host")
    private var _host:String;

    private var server:js.node.net.Server;

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
        initResult(__enabled);
    }

    override public function close():INetServerService
    {
        if (_isOpened)
        {
            server.close((?error:Error) -> {
                _isOpened = false;
                dispatchMessage(NetServerServiceMessageType.Closed);
            });
        }

        return this;
    }

    override private function createServer():Void
    {
        server = Net.createServer((socket:Socket) -> {
            handleClientConnected(socket);
            
            dispatchMessage(SocketServerServiceMessageType.ClientConnected);

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
                        var req:RequestResponse = reqMap.get(reqData.id);
                        if (req != null)
                        {
                            _requestData = {id: reqData.id, data: reqData.data};

                            handleRequest(untyped socket.id);

                            dispatchMessage(NetServerServiceMessageType.GotRequest);
                        } else
                        {
                            trace("Ignoring TCP request: " + reqData.id);
                        }
                    }
                }
            });

            socket.on(SocketEvent.End, () -> {
                handleClientDisconnected(socket);

                dispatchMessage(SocketServerServiceMessageType.ClientDisconnected);
            });

            socket.on(SocketEvent.Error, (error:Error) -> {
                trace(error);

                handleClientDisconnected(socket);
                handleSocketConnectionLost(socket);

                dispatchMessage(SocketServerServiceMessageType.ClientDisconnected);
            });
        });

        server.on(SocketEvent.Error, (error:Error) -> {
            trace(error);
        });

        server.listen(_port, _host, () -> {
            trace("TCP server created: " + _host + ":" + _port);

            _isOpened = true;

            dispatchMessage(NetServerServiceMessageType.Opened);
        });
    }

    private function handleSocketConnectionLost(socket:Socket):Void
    {

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

    private function handleRequest(clientId:Int):Void
    {
    }

    public function sendResponse(clientId:Int, response:RequestResponse):ISocketServerService
    {
        if (!clientIdMap.exists(clientId))
        {
            throw haxe.io.Error.Custom("Client with id " + clientId + " doesn't exist!");
        }

        clientIdMap.get(clientId).socket.write(Json.stringify(response) + "\n");

        return this;
    }

    public function disconnectClient(clientId:Int):ISocketServerService
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

    public function disconnectAllClients():ISocketServerService
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

    private function get_disconnectedClientId():Int
    {
        return _disconnectedClientId;
    }

    private function get_connectedClientId():Int
    {
        return _connectedClientId;
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