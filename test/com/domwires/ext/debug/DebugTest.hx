package com.domwires.ext.debug;

import com.domwires.ext.debug.mock.MockCommand;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.context.IAppContext;
import com.domwires.ext.debug.mock.IMockModel;
import com.domwires.ext.utils.Debug;
import utest.Assert;
import utest.Test;

class DebugTest extends Test
{
    public function testExecuteCommand():Void
    {
        MockCommand;

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