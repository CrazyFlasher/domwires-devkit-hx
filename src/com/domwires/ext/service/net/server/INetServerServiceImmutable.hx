package com.domwires.ext.service.net.server;

interface INetServerServiceImmutable extends IServiceIImmutable
{
    function getPort(type:ServerType):Int;
    function getHost(type:ServerType):String;
    function getQueryParam(id:String):String;

    var requestData(get, never):RequestResponse;
    var isOpened(get, never):Bool;
    var connectionsCount(get, never):Int;
}
