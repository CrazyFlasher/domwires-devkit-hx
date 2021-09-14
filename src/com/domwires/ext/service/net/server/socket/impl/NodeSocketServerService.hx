package com.domwires.ext.service.net.server.socket.impl;

import com.domwires.ext.service.net.server.INetServerService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import com.domwires.ext.service.net.server.socket.AbstractSocketServerService.AbstractSocketClient;
import js.lib.Error;
import js.node.http.ClientRequest;
import js.node.net.Server;
import js.node.net.Socket;
import js.node.Net;

class NodeSocketServerService extends AbstractSocketServerService implements ISocketServerService
{
    private var server:js.node.net.Server;

    private var nextClientId:Int = 1;

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

                    var reqData:RequestResponse = validateRequest(untyped socket.id, data);

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
            throw com.domwires.ext.Error.Custom("Client with id " + clientId + " doesn't exist!");
        }

        _disconnectedClientId = clientId;

        clientIdMap.remove(clientId);
        socket.destroy();

        trace("Client disconnected: id: " + clientId + "; Total clients: " + _connectionsCount);
    }
}

class SocketClient extends AbstractSocketClient
{
    public var socket(get, never):Socket;

    @Inject("SocketClient_socket")
    private var _socket:Socket;

    private function get_socket():Socket
    {
        return _socket;
    }

    override public function close():Void
    {
        _socket.end();
    }

    override public function write(data:String):Void
    {
        _socket.write(data);
    }
}