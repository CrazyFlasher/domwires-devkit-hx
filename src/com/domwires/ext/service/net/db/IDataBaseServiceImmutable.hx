package com.domwires.ext.service.net.db;

interface IDataBaseServiceImmutable extends IServiceImmutable
{
    var isConnected(get, never):Bool;
    var result(get, never):Dynamic;
    var error(get, never):DataBaseError;
}
