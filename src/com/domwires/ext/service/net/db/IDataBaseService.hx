package com.domwires.ext.service.net.db;

interface IDataBaseService extends IDataBaseServiceImmutable extends IService
{
    function connect():IDataBaseService;
    function disconnect():IDataBaseService;
    function insert(tableName:String, itemList:Array<Dynamic>):IDataBaseService;
    function find(tableName:String, filter:Dynamic, maxCount:UInt = 1):IDataBaseService;
    function update(tableName:String, filter:Dynamic, setParams:Dynamic, single:Bool = true):IDataBaseService;
    function delete(tableName:String, filter:Dynamic, single:Bool = true):IDataBaseService;
    function dropTable(tableName:String):IDataBaseService;
}
