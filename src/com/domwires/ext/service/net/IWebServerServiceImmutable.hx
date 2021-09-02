package com.domwires.ext.service.net;

import haxe.io.Bytes;

interface IWebServerServiceImmutable extends IServiceIImmutable
{
    function getPort(type:ServerType):Int;
    function getHost(type:ServerType):String;
    function getIsOpened(type:ServerType):Bool;
    function getQueryParam(id:String):String;

    var requestData(get, never):String;
}
