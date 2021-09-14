package com.domwires.ext.service.net.server.socket;

interface ISocketClient
{
    function close():Void;
    function write(data:String):Void;
}
