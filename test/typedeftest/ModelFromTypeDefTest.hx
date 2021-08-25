package typedeftest;

import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import mock.building.BuildingTypeDef;
import mock.building.IBuildingModel;
import mock.gameObject.GameObjectModelMessageType;
import mock.gameObject.GameObjectTypeDef;
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

        var data:GameObjectTypeDef = {id: id, name: name};
        factory.mapClassNameToValue("mock.gameObject.GameObjectTypeDef", data);

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

        var data:BuildingTypeDef = {id: id, name: name, creationTime: creationTime, maxUnits: maxUnits};
        factory.mapClassNameToValue("mock.gameObject.GameObjectTypeDef", data);
        factory.mapClassNameToValue("mock.building.BuildingTypeDef", data);

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
        var data:GameObjectTypeDef = {id: "id", name: "name"};
        factory.mapClassNameToValue("mock.gameObject.GameObjectTypeDef", data);

        var model:IGameObjectModel = factory.getInstance(IGameObjectModel);
        model.addMessageListener(GameObjectModelMessageType.OnSetId, m -> {
            Assert.isTrue(true);
            async.done();
        });
        model.dispatchMessage(GameObjectModelMessageType.OnSetId);
    }
}
