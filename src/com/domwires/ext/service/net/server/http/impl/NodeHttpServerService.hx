package com.domwires.ext.service.net.server.http.impl;

import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import js.lib.Error;
import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import js.node.Http;
import js.node.net.Server;
import js.node.net.Socket;
import js.node.url.URL;
import js.node.url.URLSearchParams;

class NodeHttpServerService extends AbstractService implements IHttpServerService
{
    @Inject("IHttpServerService_enabled")
    @Optional
    private var __enabled:Bool;

    @Inject("IHttpServerService_port")
    private var _port:Int;

    @Inject("IHttpServerService_host")
    private var _host:String;

    public var requestData(get, never):RequestResponse;
    private var _requestData:RequestResponse;

    private var queryParams:URLSearchParams;

    private var server:js.node.http.Server;

    public var isOpened(get, never):Bool;
    private var _isOpened:Bool = false;

    private var reqMap:Map<String, RequestResponse> = [];

    override private function init():Void
    {
        initResult(__enabled);
    }

    public function close():IHttpServerService
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

    override public function dispose():Void
    {
        close();

        super.dispose();
    }

    override private function initSuccess():Void
    {
        super.initSuccess();

        createServer();
    }

    private function createServer():Void
    {
        server = Http.createServer((message:IncomingMessage, response:ServerResponse) -> {
            var isHttps:Bool = message.connection.encrypted;
            var requestUrl:URL = new URL(message.url, (isHttps ? "https" : "http") + "://" + _host);
            var req:RequestResponse = reqMap.get(requestUrl.pathname);
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

                    handleRequest(message);

                    dispatchMessage(NetServerServiceMessageType.GotRequest);

                    sendResponse(response);

                    dispatchMessage(NetServerServiceMessageType.SendResponse);
                });
            } else
            {
                response.statusCode = 404;
                response.end();
            }
        });

        server.listen(_port, _host, () -> {
            trace("HTTP server created: " + _host + ":" + _port);

            _isOpened = true;

            dispatchMessage(NetServerServiceMessageType.Opened);
        });
    }

    private function handleRequest(message:IncomingMessage):Void
    {
        
    }

    private function sendResponse(response:ServerResponse):Void
    {
        response.writeHead(200, {
            "Content-Length": "0",
            "Content-Type": "text/plain; charset=utf-8"
        });
        response.end();
    }

    public function startListen(request:RequestResponse):IHttpServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        if (!reqMap.exists(request.id))
        {
            reqMap.set(request.id, request);
        }

        return this;
    }

    public function stopListen(request:RequestResponse):IHttpServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        if (reqMap.exists(request.id))
        {
            reqMap.remove(request.id);
        }

        return this;
    }

    public function getQueryParam(id:String):String
    {
        if (queryParams == null) return null;

        return queryParams.get(id);
    }

    private function get_requestData():RequestResponse
    {
        return _requestData;
    }

    private function get_isOpened():Bool
    {
        return _isOpened;
    }

    private function checkIsOpened():Bool
    {
        if (!checkEnabled()) return false;
        
        if (!_isOpened)
        {
            trace("Server is not opened!");

            return false;
        }

        return true;
    }
}