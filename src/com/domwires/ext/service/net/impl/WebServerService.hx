package com.domwires.ext.service.net.impl;

import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import js.node.Http;
import js.node.net.Socket;
import js.node.Net;

class WebServerService extends AbstractService implements IWebServerService
{
    @Inject("IWebServerService_enabled") @Optional
    private var __enabled:Bool;

    @Inject("IWebServerService_httpPort")
    private var _httpPort:Int;

    @Inject("IWebServerService_tcpPort")
    private var _tcpPort:Int;

    private var httpServer:js.node.http.Server;
    private var tcpServer:js.node.net.Server;

    private var isOpenedHttp:Bool = false;
    private var isOpenedTcp:Bool = false;

    override private function init():Void
    {
        initResult(__enabled);
    }

    public function close(?type:ServerType):IWebServerService
    {
        if (httpServer != null && (type == null || type == ServerType.Http))
        {
            httpServer.close(() ->
            {
                isOpenedHttp = false;
                dispatchMessage(WebServerServiceMessageType.HttpClosed);
            });
        }

        if (tcpServer != null && (type == null || type == ServerType.Tcp))
        {
            tcpServer.close(() ->
            {
                isOpenedTcp = false;
                dispatchMessage(WebServerServiceMessageType.TcpClosed);
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

        createServerHttp();
        createServerTcp();
    }

    private function createServerHttp():Void
    {
        httpServer = Http.createServer((request:IncomingMessage, response:ServerResponse) ->
        {
            response.writeHead(200, {'Content-Type': 'text/plain'});
            response.end('Echo http');

            dispatchMessage(WebServerServiceMessageType.GotRequest);
        });

        httpServer.listen(_httpPort, "127.0.0.1");

        isOpenedHttp = true;
    }

    private function createServerTcp():Void
    {
        tcpServer = Net.createServer((socket:Socket) ->
        {
            socket.write("Echo socket");
            socket.pipe(socket);

            dispatchMessage(WebServerServiceMessageType.ClientConnected);
        });

        tcpServer.listen(_tcpPort, "127.0.0.1");

        isOpenedTcp = true;
    }

    public function listen(value:Array<Request>):IWebServerService
    {
        return this;
    }

    public function getPort(type:ServerType):Int
    {
        if (type == ServerType.Http)
        {
            return _httpPort;
        }

        return _tcpPort;
    }

    public function getIsOpened(type:ServerType):Bool
    {
        if (type == ServerType.Http)
        {
            return isOpenedHttp;
        }

        return isOpenedTcp;
    }
}
