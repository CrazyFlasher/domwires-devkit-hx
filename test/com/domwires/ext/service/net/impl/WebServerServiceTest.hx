package com.domwires.ext.service.net.impl;

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

    public function setupClass():Void
    {
    }

    public function teardownClass():Void
    {
    }

    public function setup():Void
    {
        factory = new AppFactory();
        factory.mapToType(IWebServerService, WebServerService);
        factory.mapClassNameToValue("Int", 3000, "IWebServerService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "IWebServerService_tcpPort");
    }

    public function teardown():Void
    {
        factory.clear();
        service.dispose();
    }

    @:timeout(5000)
    public function testClose(async:Async):Void
    {
        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.HttpClosed, m -> {
            Assert.isFalse(service.getIsOpened(ServerType.Http));

            service.close(ServerType.Tcp);
        });

        service.addMessageListener(WebServerServiceMessageType.TcpClosed, m -> {
            Assert.isFalse(service.getIsOpened(ServerType.Tcp));

            async.done();
        });

        service.close(ServerType.Http);
    }

    @:timeout(5000)
    public function testHandlerHttpRequest(async:Async):Void
    {
        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.GotRequest, m -> {
            Assert.isFalse(false);
            async.done();
        });

        Http.request("http://127.0.0.1:3000").end();
    }

    @:timeout(5000)
    public function testHandlerTcpConnect(async:Async):Void
    {
        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.ClientConnected, m -> {
            Assert.isFalse(false);
            async.done();
        });

        Net.connect({port: 3001, host: "127.0.0.1"});
    }
}
