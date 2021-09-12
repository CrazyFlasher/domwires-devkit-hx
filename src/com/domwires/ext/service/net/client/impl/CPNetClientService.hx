package com.domwires.ext.service.net.client.impl;

import haxe.Http;
import hx.ws.WebSocket;
import hx.ws.Log;

class CPNetClientService extends AbstractNetClientService implements INetClientService
{
    private var client:WebSocket;

    override private function init():Void
    {
        super.init();

        Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
    }

    override public function connect():INetClientService
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

        client = new WebSocket("ws://" + _tcpHost + ":" + _tcpPort);

        client.onopen = () -> {
            _isConnected = true;

            handleConnect();

            dispatchMessage(NetClientServiceMessageType.Connected);
        };

        client.onmessage = (data:Dynamic) -> {
            var resData:RequestResponse = validateResponse(data);

            _responseData = {id: resData.id, data: resData.data};

            handleTcpResponse();

            dispatchMessage(NetClientServiceMessageType.TcpResponse);
        };

        client.onclose = () -> {
            _isConnected = false;

            handleDisconnect();

            dispatchMessage(NetClientServiceMessageType.Disconnected);
        };

        client.onerror = err -> {
            trace(err.error);
        }

        return this;
    }

    override public function disconnect():INetClientService
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

        return this;
    }

    override private function sendHttpRequest(request:RequestResponse, type:RequestType):Void
    {
        var http:Http = new Http("http://" + _httpHost + ":" + _httpPort + "/" + request.id);
        http.addHeader("Content-Type", "application/json");
        http.setPostData(request.data);

        var arr:Array<String> = request.id.split("?");
        if (arr.length > 1)
        {
            arr = arr[1].split("&");
            for (param in arr)
            {
                var split:Array<String> = param.split("=");
                if (split.length > 1)
                {
                    http.setParameter(split[0], split[1]);
                }
            }
        }

        http.onData = (data:String) -> {
            _responseData = {id: "/" + request.id, data: data};

            handleHttpResponse(data);

            dispatchMessage(NetClientServiceMessageType.HttpResponse);
        };
        http.onError = error -> trace("HTTP request error: " + error);

        http.request(type == RequestType.Post);
    }

    override private function sendTcpRequest(request:RequestResponse):Void
    {
        client.send(messageToSend);
    }
}
