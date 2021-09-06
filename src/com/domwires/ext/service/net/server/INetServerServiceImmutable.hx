package com.domwires.ext.service.net.server;

interface INetServerServiceImmutable extends IServiceIImmutable
{
    function getPort(type:ServerType):Int;
    function getHost(type:ServerType):String;
    function isOpened(type:ServerType):Bool;
    function getQueryParam(id:String):String;

    var requestData(get, never):RequestResponse;
    var connectionsCount(get, never):Int;
}
