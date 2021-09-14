package com.domwires.ext.service.net.server.socket.impl;

import com.domwires.core.mvc.message.IMessageDispatcher;
import com.domwires.core.mvc.message.MessageDispatcher;
import com.domwires.ext.service.net.server.INetServerService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import hx.ws.Log;
import hx.ws.SocketImpl;
import hx.ws.Types.MessageType;
import hx.ws.WebSocketHandler;
import hx.ws.WebSocketServer;

class WebSocketServerService extends AbstractSocketServerService implements ISocketServerService
{
    private var server:WebSocketServer<WebSocketClient>;

    override public function close():INetServerService
    {
        if (_isOpened)
        {
            server.stop(() -> {
                _isOpened = false;
                dispatchMessage(NetServerServiceMessageType.Closed);
            });
        }

        return this;
    }

    override private function createServer():Void
    {
        server = new WebSocketServer<WebSocketClient>(_host, _port);
        Log.mask = Log.INFO | Log.DEBUG | Log.DATA;

        server.onClientAdded = (handler:WebSocketClient) -> {
            var dispatcher:IMessageDispatcher = new MessageDispatcher();
            dispatcher.addMessageListener(SocketClientMessageType.Connected, m -> {
                handleClientConnected(handler);
                dispatchMessage(SocketServerServiceMessageType.ClientConnected);
            });
            dispatcher.addMessageListener(SocketClientMessageType.Disconnected, m -> {
                handleClientDisconnected(handler);
                dispatchMessage(SocketServerServiceMessageType.ClientDisconnected);
            });
            dispatcher.addMessageListener(SocketClientMessageType.Error, m -> {
                trace(handler.error);
                handleClientDisconnected(handler);
                dispatchMessage(SocketServerServiceMessageType.ClientDisconnected);
            });
            dispatcher.addMessageListener(SocketClientMessageType.Data, m -> {
                var data:String = handler.data;
                _requestData = null;

                var reqData:RequestResponse = validateRequest(handler.clientId, data);

                if (reqData != null)
                {
                    var req:RequestResponse = reqMap.get(reqData.id);
                    if (req != null)
                    {
                        _requestData = {id: reqData.id, data: reqData.data};

                        handleRequest(handler.clientId);

                        dispatchMessage(NetServerServiceMessageType.GotRequest);
                    } else
                    {
                        trace("Ignoring TCP request: " + reqData.id);
                    }
                }
            });

            handler.dispatcher = dispatcher;
        }

        server.start(() -> {
            trace("TCP server created: " + _host + ":" + _port);

            _isOpened = true;

            dispatchMessage(NetServerServiceMessageType.Opened);
        });
    }

    private function handleClientConnected(socket:WebSocketClient):Void
    {
        _connectionsCount++;

        _connectedClientId = socket.clientId;

        clientIdMap.set(_connectedClientId, socket);

        trace("Client connected: id: " + _connectedClientId + "; Total clients: " + _connectionsCount);
    }

    private function handleClientDisconnected(socket:WebSocketClient):Void
    {
        _connectionsCount--;

        if (!clientIdMap.exists(socket.clientId))
        {
            throw com.domwires.ext.Error.Custom("Client with id " + socket.clientId + " doesn't exist!");
        }

        _disconnectedClientId = socket.clientId;

        clientIdMap.remove(socket.clientId);

        trace("Client disconnected: id: " + socket.clientId + "; Total clients: " + _connectionsCount);

        socket.dispose();
    }
}

class WebSocketClient extends WebSocketHandler implements ISocketClient
{
    public var dispatcher:IMessageDispatcher;

    public var clientId(get, never):Int;
    private var _clientId:Int;

    public var data(get, never):String;
    private var _data:String;

    public var error(get, never):Dynamic;
    private var _error:Dynamic;

    public function new(socket:SocketImpl)
    {
        super(socket);

        onopen = function()
        {
            _clientId = id;

            dispatcher.dispatchMessage(SocketClientMessageType.Connected);
        }
        onclose = function()
        {
            dispatcher.dispatchMessage(SocketClientMessageType.Disconnected);
        }
        onmessage = function(message:MessageType)
        {
            switch (message) {
                case StrMessage(content):
                    _data = content;
                    dispatcher.dispatchMessage(SocketClientMessageType.Data);

                case BytesMessage(content):
                    trace(content);
                    throw com.domwires.ext.Error.NotImplemented;
            }
        }
        onerror = function(error)
        {
            _error = error;

            dispatcher.dispatchMessage(SocketClientMessageType.Error);
        }
    }

    public function write(data:String):Void
    {
        send(data);
    }

    public function dispose() 
    {
        dispatcher.dispose();
    }

    private function get_clientId():Int
    {
        return _clientId;
    }

    private function get_data():String
    {
        return _data;
    }

    private function get_error():Dynamic
    {
        return _error;
    }
}

enum SocketClientMessageType
{
    Connected;
    Disconnected;
    Data;
    Error;
}