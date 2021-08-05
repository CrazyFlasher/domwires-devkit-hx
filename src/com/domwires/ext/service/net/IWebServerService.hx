package com.domwires.ext.service.net;

interface IWebServerService extends IWebServerServiceImmutable extends IService
{
    function listen(value:Array<RequestVo>):IWebServerService;
    function close():IWebServerService;
}
