package com.domwires.ext.service.net;

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
    private var factory:IAppFactory;
    private var db:DummyDb;

    public function setup():Void
    {
        factory = new AppFactory();

        factory.mapToType(IDataBaseService, DummyDb);

        factory.mapClassNameToValue("String", "mongodb://127.0.0.1:27017", "IDataBaseService_uri");
        factory.mapClassNameToValue("String", "test_data_base", "IDataBaseService_dataBaseName");
    }

    @:timeout(2000)
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
            db.dropTable("testTable");
        } else
        {
            db.dispose();
            async.done();
        }
    }

    @:timeout(2000)
    public function testConnectDisconnect(async:Async):Void
    {
        db = cast factory.getInstance(IDataBaseService);
        db.addMessageListener(DataBaseServiceMessageType.Connected, m -> {
            Assert.isTrue(db.isConnected);

            db.disconnect();
        });
        db.addMessageListener(DataBaseServiceMessageType.Disconnected, m -> {
            Assert.isFalse(db.isConnected);

            async.done();
        });

        db.connect();
    }

    @:timeout(2000)
    public function testInsertFindUpdateDelete(async:Async):Void
    {
        db = cast factory.getInstance(IDataBaseService);

        db.addMessageListener(DataBaseServiceMessageType.DeleteResult, m -> {
            db.addMessageListener(DataBaseServiceMessageType.FindResult, m -> {
                Assert.isNull(db.getResult());
                
                async.done();
            });

            db.find("testTable", {lastName: "Pukallo"});
        });
        db.addMessageListener(DataBaseServiceMessageType.UpdateResult, m -> {
            db.find("testTable", {firstName: "Anton"});
        });
        db.addMessageListener(DataBaseServiceMessageType.FindResult, findCb_1);
        db.addMessageListener(DataBaseServiceMessageType.InsertResult, m -> {
            db.find("testTable", {firstName: "Anton"});
        });
        db.addMessageListener(DataBaseServiceMessageType.Connected, m -> {
            db.insert("testTable", [{firstName: "Anton", lastName: "Nefjodov"}]);
        });

        db.connect();
    }

    private function findCb_1(m:IMessage):Void
    {
        db.removeMessageListener(DataBaseServiceMessageType.FindResult, findCb_1);
        db.addMessageListener(DataBaseServiceMessageType.FindResult, findCb_2);

        Assert.equals("Anton", db.getResult().firstName);

        db.update("testTable", {firstName: "Anton"}, {lastName: "Pukallo"});
    }

    private function findCb_2(m:IMessage):Void
    {
        db.removeMessageListener(DataBaseServiceMessageType.FindResult, findCb_2);

        Assert.equals("Pukallo", db.getResult().lastName);

        db.delete("testTable", {lastName:"Pukallo"});
    }
}

class DummyDb extends NodeMongoDatabaseService
{
    public function getResult():Dynamic
    {
        return result;
    }
}