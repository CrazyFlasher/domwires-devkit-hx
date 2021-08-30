package com.domwires.ext.service.net;

interface IWebServerService extends IWebServerServiceImmutable extends IService
{
    function listen(value:Array<Request>):IWebServerService;
    function close():IWebServerService;
}
