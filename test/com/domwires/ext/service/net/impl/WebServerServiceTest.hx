package com.domwires.ext.service.net.impl;

import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.IWebServerService;
import com.domwires.ext.service.net.WebServerServiceMessageType;
import com.domwires.ext.service.net.impl.WebServerService;
import js.node.Http;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

class WebServerServiceTest
{
    private var factory:IAppFactory;
    private var service:IWebServerService;

    @BeforeClass
    public function beforeClass():Void
    {
    }

    @AfterClass
    public function afterClass():Void
    {
    }

    @Before
    public function setup():Void
    {
        factory = new AppFactory();
        factory.mapToType(IWebServerService, WebServerService);
        factory.mapClassNameToValue("Int", 3000, "IWebServerService_port");
    }

    @After
    public function tearDown():Void
    {
        factory.clear();
        service.dispose();
    }

    /*@Test
    public function testDisabled(af:AsyncFactory):Void
    {
        var handler:Dynamic = af.createHandler(this, () -> Assert.isFalse(service.enabled), 2000);

        factory.mapClassNameToValue("Bool", false, "IWebServerService_enabled");

        service = factory.getInstance(IWebServerService);

        Assert.isFalse(service.enabled);
    }

    @Test
    public function testEnabled(af:AsyncFactory):Void
    {
        service = factory.getInstance(IWebServerService);

        Assert.isTrue(service.enabled);
    }*/

    @AsyncTest
    public function testClose(af:AsyncFactory):Void
    {
        var handler:Dynamic = af.createHandler(this, () -> Assert.isFalse(service.isOpened), 5000);

        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.Closed, handler);
        service.close();
    }

    @AsyncTest
    public function testHandlerRequest(af:AsyncFactory):Void
    {
        var handler:Dynamic = af.createHandler(this, () -> Assert.isFalse(false), 5000);

        service = factory.getInstance(IWebServerService);
        service.addMessageListener(WebServerServiceMessageType.GotRequest, handler);

        Http.request("http://127.0.0.1:3000").end();
    }
}
