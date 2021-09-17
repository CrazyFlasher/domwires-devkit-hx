package com.domwires.ext.service.net.server.http.impl;

import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import haxe.DynamicAccess;
import js.lib.Error;
import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import js.node.Http;
import js.node.net.Server;
import js.node.net.Socket;
import js.node.url.URL;
import js.node.url.URLSearchParams;

final class NodeHttpServerService extends AbstractNetServerService implements IHttpServerService
{
    @Inject("IHttpServerService_enabled")
    @Optional
    private var __enabled:Bool;

    @Inject("IHttpServerService_port")
    private var _port:Int;

    @Inject("IHttpServerService_host")
    private var _host:String;

    private var queryParams:URLSearchParams;

    private var server:js.node.http.Server;

    private var pendingResponse:ServerResponse;

    override private function init():Void
    {
        initResult(__enabled);
    }

    override public function close():IHttpServerService
    {
        if (_isOpened)
        {
            if (pendingResponse != null)
            {
                pendingResponse.end();
                pendingResponse = null;
            }

            server.close((?error:Error) -> {
                _isOpened = false;
                dispatchMessage(NetServerServiceMessageType.Closed);
            });
        }

        return this;
    }

    override private function createServer():Void
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
                    pendingResponse = response;

                    queryParams = requestUrl.searchParams;

                    dispatchMessage(NetServerServiceMessageType.GotRequest);
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

    public function sendResponse(response:RequestResponse, statusCode:Int = 200, ?customHeaders:DynamicAccess<String>):IHttpServerService
    {
        if (pendingResponse == null)
        {
            throw com.domwires.ext.Error.Custom("There are no pending response!");
        }

        if (response.id != _requestData.id)
        {
            throw com.domwires.ext.Error.Custom("Response id should be the same as request id!");
        }

        var headers:DynamicAccess<String>;
        if (customHeaders == null)
        {
            headers = {
                "Content-Type": "text/plain; charset=utf-8"
            };
        } else
        {
            headers = customHeaders;
        }

        pendingResponse.writeHead(statusCode, headers);
        if (response.data != null )
        {
            pendingResponse.write(response.data);
        }
        pendingResponse.end();

        pendingResponse = null;

        return this;
    }

    public function getQueryParam(id:String):String
    {
        if (queryParams == null) return null;

        return queryParams.get(id);
    }
}