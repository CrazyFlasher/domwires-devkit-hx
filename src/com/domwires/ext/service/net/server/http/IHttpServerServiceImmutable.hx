package com.domwires.ext.service.net.server.http;

interface IHttpServerServiceImmutable extends INetServerServiceImmutable
{
    function getQueryParam(id:String):String;
}
