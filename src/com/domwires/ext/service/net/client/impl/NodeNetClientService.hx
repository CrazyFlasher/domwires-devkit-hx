package com.domwires.ext.service.net.client.impl;

import js.node.net.Socket;
import js.node.Net;
import js.node.http.IncomingMessage;
import js.node.Http;
import js.node.http.ClientRequest;
import js.node.http.Method;
import js.node.Http.HttpRequestOptions;

class NodeNetClientService extends AbstractService implements INetClientService
{
    @Inject("INetClientService_enabled")
    @Optional
    private var __enabled:Bool;

    @Inject("INetClientService_httpPort")
    private var _httpPort:Int;

    @Inject("INetClientService_tcpPort")
    private var _tcpPort:Int;

    @Inject("INetClientService_httpHost")
    private var _httpHost:String;

    @Inject("INetClientService_tcpHost")
    private var _tcpHost:String;

    private var client:Socket;

    public var responseData(get, never):String;
    private var _responseData:String;

    public var isConnected(get, never):Bool;
    private var _isConnected:Bool = false;

    override private function init():Void
    {
        initResult(__enabled);
    }

    private function isHttp(type:RequestType):Bool
    {
        return type != RequestType.Tcp;
    }

    public function connect():INetClientService
    {
        if (!checkEnabled())
        {
            return this;
        }

        if (_isConnected)
        {
            trace("Client already connected!");

            return this;
        }

        client = Net.connect({port: _tcpPort, host: _tcpHost}, () ->
        {
            client.on(SocketEvent.End, () -> 
            {
                _isConnected = false;

                handleDisconnect();

                dispatchMessage(NetClientServiceMessageType.Disconnected);
            });

            _isConnected = true;

            handleConnect();

            dispatchMessage(NetClientServiceMessageType.Connected);
        });

        return this;
    }

    public function disconnect():INetClientService
    {
        if (!checkEnabled())
        {
            return this;
        }

        if (!_isConnected)
        {
            trace("Client is disconnected!");

            return this;
        }

        client.end();

        return this;
    }

    public function send(request:RequestResponse):INetClientService
    {
        if (!checkEnabled())
        {
            return this;
        }

        if (isHttp(request.type))
        {
            sendHttpRequest(request);
        } else
        {
            sendTcpRequest(request);
        }

        return this;
    }

    private function sendHttpRequest(request:RequestResponse):INetClientService
    {
        var method:Method;
        if (request.type == RequestType.Post)
        {
            method = Method.Post;
        } else
        {
            method = Method.Get;
        }

        var length:Int = (request.data != null ? request.data.length : 0);
        var options:HttpRequestOptions = {
            hostname: _httpHost,
            method: method,
            port: _httpPort,
            path: "/" + request.id,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Std.string(length)
            }
        };

        var req:ClientRequest = Http.request(options, (message:IncomingMessage) ->
        {
            var data:String = "";
            message.on("data", (chunk:String) -> 
            {
                data += chunk;
                trace(data);
            });
            message.on("end", () ->
            {
                _responseData = data;

                handleHttpResponse(message);

                dispatchMessage(NetClientServiceMessageType.HttpResponse);
            });
        });

        if (request.data != null)
        {
            req.write(request.data);
        }
        
        req.end();

        return this;
    }

    private function sendTcpRequest(request:RequestResponse):INetClientService
    {
        if (request.data == null)
        {
            trace("Nothing to send");

            return this;
        }

        client.write(request.data);

        return this;
    }

    private function handleConnect():Void
    {

    }

    private function handleDisconnect():Void
    {

    }
    
    private function handleHttpResponse(message:IncomingMessage):Void
    {

    }

    private function get_responseData():String
    {
        return _responseData;
    }

    private function get_isConnected():Bool
    {
        return _isConnected;
    }
}
