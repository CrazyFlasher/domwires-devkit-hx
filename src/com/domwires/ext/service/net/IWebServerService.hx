package com.domwires.ext.service.net;

interface IWebServerService extends IWebServerServiceImmutable extends IService
{
    function startListen(request:Request):IWebServerService;
    function stopListen(request:Request):IWebServerService;
    function close(?type:ServerType):IWebServerService;
}
