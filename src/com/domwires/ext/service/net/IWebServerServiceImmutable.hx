package com.domwires.ext.service.net;

interface IWebServerServiceImmutable extends IServiceIImmutable
{
    var port(get, never):Int;
    var isOpened(get, never):Bool;
}
