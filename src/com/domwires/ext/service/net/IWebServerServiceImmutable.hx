package com.domwires.ext.service.net;

interface IWebServerServiceImmutable extends IServiceIImmutable
{
    function getPort(type:ServerType):Int;
    function getIsOpened(type:ServerType):Bool;
}
