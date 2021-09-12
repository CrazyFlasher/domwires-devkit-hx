package com.domwires.ext.service.net.client.impl;

import haxe.Json;

class AbstractNetClientService extends AbstractService implements INetClientService
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

    public var responseData(get, never):RequestResponse;
    private var _responseData:RequestResponse;

    public var isConnected(get, never):Bool;
    private var _isConnected:Bool = false;

    private var messageToSend:String;

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
        throw Error.Override;
    }

    public function disconnect():INetClientService
    {
        throw Error.Override;
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
            messageToSend = prepareTcpRequestMessage(request);
            sendTcpRequest(request);
        }

        return this;
    }

    private function prepareTcpRequestMessage(request:RequestResponse):String
    {
        if (!_isConnected)
        {
            throw Error.Custom("Cannot send TCP request! Not connected!");
        }

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

        return message + "\n";
    }

    private function sendHttpRequest(request:RequestResponse, type:RequestType):Void
    {
        throw Error.Override;
    }

    private function sendTcpRequest(request:RequestResponse):Void
    {
        throw Error.Override;
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

    private function handleHttpResponse(data:String):Void
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
