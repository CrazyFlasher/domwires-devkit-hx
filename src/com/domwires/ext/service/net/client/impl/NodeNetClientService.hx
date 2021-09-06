package com.domwires.ext.service.net.client.impl;

import haxe.Json;
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

    public var responseData(get, never):RequestResponse;
    private var _responseData:RequestResponse;

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

        client = cast Net.connect({port: _tcpPort, host: _tcpHost}, () ->
        {
            client.on(SocketEvent.End, () -> 
            {
                _isConnected = false;

                handleDisconnect();

                dispatchMessage(NetClientServiceMessageType.Disconnected);
            });

            var received:MessageBuffer = new MessageBuffer();

            client.on(SocketEvent.Data, (chunk:String) ->
            {
                received.push(chunk);
                while (!received.isFinished())
                {
                    var data:String = received.handleData();
                    var resData:RequestResponse = validateResponse(data);

                    _responseData = {id: resData.id, data: resData.data};

                    handleTcpResponse();

                    dispatchMessage(NetClientServiceMessageType.TcpResponse);
                }
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

    public function send(request:RequestResponse, type:RequestType):INetClientService
    {
        if (!checkEnabled())
        {
            return this;
        }

        if (isHttp(type))
        {
            sendHttpRequest(request, type);
        } else
        {
            sendTcpRequest(request);
        }

        return this;
    }

    private function sendHttpRequest(request:RequestResponse, type:RequestType):INetClientService
    {
        var method:Method;
        if (type == RequestType.Post)
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
                _responseData = {id: message.url, data: data};

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
        var message:String = "";

        if (request.data == null)
        {
            message = "{\"id\":\"" + request.id + "\"}";
        } else
        {
            var json:Dynamic = {
                id: request.id,
                data: request.data
            };
            message = Json.stringify(json);
        }

        client.write(message + "\n");

        return this;
    }

    private function validateResponse(data:String):RequestResponse
    {
        var resData:RequestResponse;

        try
        {
            resData = Json.parse(data);
        } catch (e:js.lib.Error)
        {
            throw haxe.io.Error.Custom("Response should be a JSON string: " + data);
        }

        if (resData.id == null)
        {
            throw haxe.io.Error.Custom("Response Json should contain \"id\" field!: " + data);
        }

        return resData;
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

    private function handleTcpResponse():Void
    {

    }

    private function get_responseData():RequestResponse
    {
        return _responseData;
    }

    private function get_isConnected():Bool
    {
        return _isConnected;
    }

}
