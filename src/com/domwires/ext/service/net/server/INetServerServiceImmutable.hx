package com.domwires.ext.service.net.server;

interface INetServerServiceImmutable extends IServiceImmutable
{
    var requestData(get, never):RequestResponse;
    var isOpened(get, never):Bool;
}
