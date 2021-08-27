package typedeftest;

import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import mock.Building;
import mock.CrazyFormat1;
import mock.GameObject;
import mock.building.IBuildingModel;
import mock.crazyFormat1.ICrazyFormat1Model;
import mock.gameObject.GameObjectModelMessageType;
import mock.gameObject.IGameObjectModel;
import utest.Assert;
import utest.Async;
import utest.Test;

class ModelFromTypeDefTest extends Test
{
    private var factory:IAppFactory;

    public function setupClass():Void
    {
        factory = new AppFactory();
    }

    public function teardown():Void
    {
        factory.clear();
    }

    public function testBaseTypeDef():Void
    {
        var id:String = "some_object_1";
        var name:String = "cool_game_object";

        var data:GameObject = {id: id, name: name};
        factory.mapClassNameToValue("mock.GameObject", data);

        var model:IGameObjectModel = factory.getInstance(IGameObjectModel);

        Assert.equals(id, model.id);
        Assert.equals(name, model.name);

        model.setId("go").setName("ololo");

        Assert.equals("go", model.id);
        Assert.equals("ololo", model.name);
    }

    public function testExtendedTypeDef():Void
    {
        var id:String = "some_object_1";
        var name:String = "cool_game_object";
        var creationTime:Int = 12345;
        var maxUnits:Int = 4;

        var data:Building = {
            id: id,
            name: name,
            creationTime: creationTime,
            maxUnits: maxUnits
        };

        factory.mapClassNameToValue("mock.GameObject", data);
        factory.mapClassNameToValue("mock.Building", data);

        var model:IBuildingModel = factory.getInstance(IBuildingModel);

        Assert.equals(id, model.id);
        Assert.equals(name, model.name);
        Assert.equals(creationTime, model.creationTime);
        Assert.equals(maxUnits, model.maxUnits);

        model.setId("go").setName("ololo");
        model.setCreationTime(1).setMaxUnits(2);

        Assert.equals("go", model.id);
        Assert.equals("ololo", model.name);
        Assert.equals(1, model.creationTime);
        Assert.equals(2, model.maxUnits);
    }

    public function testTypeDefMessage(async:Async):Void
    {
        var data:GameObject = {id: "id", name: "name"};
        factory.mapClassNameToValue("mock.GameObject", data);

        var model:IGameObjectModel = factory.getInstance(IGameObjectModel);
        model.addMessageListener(GameObjectModelMessageType.OnSetId, m ->
        {
            Assert.isTrue(true);
            async.done();
        });
        model.dispatchMessage(GameObjectModelMessageType.OnSetId);
    }

    public function testUglyTypeDef():Void
    {
        var data:CrazyFormat1 = {
            a: 1,
            b: "two",
            id: "id",
            name: "name",
            maxUnits: 5,
            creationTime: 1000
        };
        factory.mapClassNameToValue("mock.GameObject", data);
        factory.mapClassNameToValue("mock.Building", data);
        factory.mapClassNameToValue("mock.CrazyFormat1", data);

        var model:ICrazyFormat1Model = factory.getInstance(ICrazyFormat1Model);

        Assert.equals(1, model.a);
        Assert.equals("two", model.b);
    }

    public function testExtendedTypeDefSamePackage():Void
    {
        var id:String = "some_object_1";
        var name:String = "cool_game_object";
        var creationTime:Int = 12345;
        var maxUnits:Int = 4;

        var data:Building = {
            id: id,
            name: name,
            creationTime: creationTime,
            maxUnits: maxUnits
        };

        factory.mapClassNameToValue("mock.GameObject", data);
        factory.mapClassNameToValue("mock.Building", data);

        var model:mock.IBuildingModel = factory.getInstance(mock.IBuildingModel);

        Assert.equals(id, model.id);
        Assert.equals(name, model.name);
        Assert.equals(creationTime, model.creationTime);
        Assert.equals(maxUnits, model.maxUnits);

        model.setId("go").setName("ololo");
        model.setCreationTime(1).setMaxUnits(2);

        Assert.equals("go", model.id);
        Assert.equals("ololo", model.name);
        Assert.equals(1, model.creationTime);
        Assert.equals(2, model.maxUnits);
    }
}
