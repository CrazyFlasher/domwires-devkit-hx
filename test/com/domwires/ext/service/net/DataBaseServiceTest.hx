package com.domwires.ext.service.net;

import com.domwires.ext.service.net.db.DataBaseError.DataBaseErrorCode;
import com.domwires.core.mvc.message.IMessage;
import utest.Async;
import com.domwires.ext.service.net.db.DataBaseServiceMessageType;
import com.domwires.ext.service.net.db.impl.NodeMongoDatabaseService;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.db.IDataBaseService;
import utest.Assert;
import utest.Test;

class DataBaseServiceTest extends Test
{
    public static final TABLE_NAME:String = "testTable";

    private var factory:IAppFactory;
    private var db:IDataBaseService;

    @:timeout(5000)
    public function setup(async:Async):Void
    {
        factory = new AppFactory();

        factory.mapToType(IDataBaseService, NodeMongoDatabaseService);

        factory.mapClassNameToValue("String", "mongodb://127.0.0.1:27017", "IDataBaseService_uri");
        factory.mapClassNameToValue("String", "test_data_base", "IDataBaseService_dataBaseName");

        db = cast factory.getInstance(IDataBaseService);

        db.addMessageListener(DataBaseServiceMessageType.CreateTableResult, m -> {
            async.done();
        });
        db.addMessageListener(DataBaseServiceMessageType.Connected, m -> {
            db.createTable(TABLE_NAME, ["lastName"]);
        });

        db.connect();
    }

    @:timeout(5000)
    public function teardown(async:Async):Void
    {
        db.addMessageListener(DataBaseServiceMessageType.Disconnected, m -> {
            db.dispose();
            async.done();
        });
        db.addMessageListener(DataBaseServiceMessageType.DropTableResult, m -> {
            db.disconnect();
        });
        db.addMessageListener(DataBaseServiceMessageType.DropTableError, m -> {
            db.disconnect();
        });

        if (db.isConnected)
        {
            db.dropTable(TABLE_NAME);
        } else
        {
            db.dispose();
            async.done();
        }
    }

    @:timeout(5000)
    public function testInsertFindUpdateDelete(async:Async):Void
    {
        db.addMessageListener(DataBaseServiceMessageType.DeleteResult, m -> {
            db.addMessageListener(DataBaseServiceMessageType.FindResult, m -> {
                Assert.isNull(db.result);
                
                async.done();
            });

            db.find(TABLE_NAME, {lastName: "Pukallo"});
        });
        db.addMessageListener(DataBaseServiceMessageType.UpdateResult, m -> {
            db.find(TABLE_NAME, {firstName: "Anton"});
        });
        db.addMessageListener(DataBaseServiceMessageType.FindResult, findCb_1);
        db.addMessageListener(DataBaseServiceMessageType.InsertResult, m -> {
            db.find(TABLE_NAME, {firstName: "Anton"});
        });

        db.insert(TABLE_NAME, [{firstName: "Anton", lastName: "Nefjodov"}]);
    }

    private function findCb_1(m:IMessage):Void
    {
        db.removeMessageListener(DataBaseServiceMessageType.FindResult, findCb_1);
        db.addMessageListener(DataBaseServiceMessageType.FindResult, findCb_2);

        Assert.equals("Anton", db.result.firstName);

        db.update(TABLE_NAME, {firstName: "Anton"}, {lastName: "Pukallo"});
    }

    private function findCb_2(m:IMessage):Void
    {
        db.removeMessageListener(DataBaseServiceMessageType.FindResult, findCb_2);

        Assert.equals("Pukallo", db.result.lastName);

        db.delete(TABLE_NAME, {lastName:"Pukallo"});
    }

    @:timeout(5000)
    public function testInsertDuplicateError(async:Async):Void
    {
        db.addMessageListener(DataBaseServiceMessageType.InsertError, m -> {
            Assert.equals(DataBaseErrorCode.Duplicate, db.error.code);
            async.done();
        });

        db.insert(TABLE_NAME, [
            {firstName: "Onton", lastName: "Ololoev"},
            {firstName: "Dzigurda", lastName: "Ololoev"}
        ]);
    }
}