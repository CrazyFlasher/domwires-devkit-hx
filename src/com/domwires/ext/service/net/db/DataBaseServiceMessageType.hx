package com.domwires.ext.service.net.db;

enum DataBaseServiceMessageType
{
    Connected;
    Disconnected;
    InsertResult;
    FindResult;
    UpdateResult;
    DeleteResult;
    DropTableResult;
    CreateTableResult;

    ConnectError;
    InsertError;
    FindError;
    UpdateError;
    DeleteError;
    DropTableError;
}