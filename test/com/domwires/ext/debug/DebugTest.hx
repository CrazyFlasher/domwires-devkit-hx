package com.domwires.ext.debug;

import utest.Assert;
import com.domwires.ext.utils.Debug;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.core.mvc.command.AbstractCommand;
import com.domwires.core.mvc.model.AbstractModel;
import com.domwires.core.mvc.model.IModel;
import com.domwires.core.mvc.model.IModelImmutable;
import com.domwires.ext.context.IAppContext;
import utest.Test;

class DebugTest extends Test
{
    public function testExecuteCommand():Void
    {
        var factory:IAppFactory = new AppFactory();
        var model:IMockModel = factory.getInstance(IMockModel);

        factory.mapToValue(IAppFactory, factory);
        factory.mapToValue(IMockModel, model);

        Debug.mapContext("main", factory.getInstance(IAppContext));
        Debug.cmd("test", {v: 7, s: "text", o: {a: 55}}, "main");

        Assert.equals(model.getV(), 7);
        Assert.equals(model.getS(), "text");
        Assert.equals(model.getO().a, 55);
    }
}

@Alias("test")
@Desc("Test Command")
class MockCommand extends AbstractCommand
{
    @Inject("v")
    private var v:Int;

    @Inject("s")
    private var s:String;

    @Inject("o")
    private var o:Dynamic;

    @Inject
    private var model:IMockModel;

    override public function execute():Void
    {
        super.execute();

        model.setV(v);
        model.setS(s);
        model.setO(o);
    }
}

class MockModel extends AbstractModel implements IMockModel
{
    private var v:Int;
    private var s:String;
    private var o:Dynamic;

    public function setV(value:Int):Void
    {
        v = value;
    }

    public function setS(value:String):Void
    {
        s = value;
    }

    public function setO(value:Dynamic):Void
    {
        o = value;
    }

    public function getV():Int
    {
        return v;
    }

    public function getS():String
    {
        return s;
    }

    public function getO():Dynamic
    {
        return o;
    }
}

interface IMockModel extends IMockModelImmutable extends IModel
{
    function setV(value:Int):Void;
    function setS(value:String):Void;
    function setO(value:Dynamic):Void;
}

interface IMockModelImmutable extends IModelImmutable
{
    function getV():Int;
    function getS():String;
    function getO():Dynamic;
}
