package com.domwires.ext.service.net.impl;

import js.node.http.ServerResponse;
import js.node.http.IncomingMessage;
import js.node.http.Server;
import js.node.Http;

class WebServerService extends AbstractService implements IWebServerService
{
    @Inject("IWebServerService_enabled") @Optional
    private var __enabled:Bool;

    @Inject("IWebServerService_port")
    private var _port:Int;

    public var port(get, never):Int;
    public var isOpened(get, never):Bool;

    private var http:Server;
    private var _isOpened:Bool;

    override private function init():Void
    {
        initResult(__enabled);
    }

    public function close():IWebServerService
    {
        if (http != null) http.close(() ->
        {
            _isOpened = false;
            dispatchMessage(WebServerServiceMessageType.Closed);
        });

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

        _isOpened = true;

        http = Http.createServer(function (request:IncomingMessage, response:ServerResponse)
        {
            response.writeHead(200, {'Content-Type': 'text/plain'});
            response.end('Hello World!');

            dispatchMessage(WebServerServiceMessageType.GotRequest);
        });

        http.listen(_port, "127.0.0.1");
    }

    public function listen(value:Array<RequestVo>):IWebServerService
    {
        return this;
    }

    private function get_port():Int
    {
        return _port;
    }

    private function get_isOpened():Bool
    {
        return _isOpened;
    }
}
