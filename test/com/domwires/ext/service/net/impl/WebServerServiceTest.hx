package com.domwires.ext.service.net.impl;

import js.node.http.Method;
import js.node.Net;
import utest.Async;
import utest.Test;
import utest.Assert;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.IWebServerService;
import com.domwires.ext.service.net.WebServerServiceMessageType;
import com.domwires.ext.service.net.impl.WebServerService;
import js.node.Http;

class WebServerServiceTest extends Test
{
    private var factory:IAppFactory;
    private var service:IWebServerService;

    public function setupClass():Void {}

    public function teardownClass():Void {}

    public function setup():Void
    {
        factory = new AppFactory();
        factory.mapToType(IWebServerService, WebServerService);
        factory.mapClassNameToValue("Int", 3000, "IWebServerService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "IWebServerService_tcpPort");
    }

    @:timeout(5000)
    public function teardown(async:Async):Void
    {
        var httpClosed:Bool = !service.getIsOpened(ServerType.Http);
        var tcpClosed:Bool = !service.getIsOpened(ServerType.Tcp);

        var complete:Void -> Void = () -> 
        {
            service.dispose();
            async.done();
        };

        service.addMessageListener(WebServerServiceMessageType.TcpClosed, m ->
        {
            tcpClosed = true;

            if (httpClosed)
            {
                complete();
            }
        });

        service.addMessageListener(WebServerServiceMessageType.HttpClosed, m ->
        {
            httpClosed = true;

            if (tcpClosed)
            {
                complete();
            }
        });

        service.close();
    }

    @:timeout(5000)
    public function testClose(async:Async):Void
    {
        var httpClosed:Bool = false;
        var tcpClosed:Bool = false;

        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.HttpClosed, m ->
        {
            httpClosed = true;
            
            Assert.isFalse(service.getIsOpened(ServerType.Http));

            service.close(ServerType.Tcp);

            if (tcpClosed) async.done();
        });

        service.addMessageListener(WebServerServiceMessageType.TcpClosed, m ->
        {
            tcpClosed = true;

            Assert.isFalse(service.getIsOpened(ServerType.Tcp));

            if (httpClosed) async.done();
        });

        service.close(ServerType.Http);
    }

    @:timeout(5000)
    public function testHandlerHttpRequest(async:Async):Void
    {
        service = factory.getInstance(IWebServerService);
        service.startListen({id: "/pizda", type: RequestType.Post});
        service.addMessageListener(WebServerServiceMessageType.GotRequest, m ->
        {
            Assert.isTrue(true);
            async.done();
        });

        Http.request({hostname: "localhost", method: Method.Post, port: 3000, path: "/pizda"}).end();
    }

    @:timeout(5000)
    public function testHandlerTcpConnect(async:Async):Void
    {
        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.ClientConnected, m ->
        {
            Assert.isTrue(true);
            async.done();
        });

        Net.connect({port: 3001, host: "127.0.0.1"}).end();
    }
}
