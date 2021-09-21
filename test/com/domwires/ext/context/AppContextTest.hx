package com.domwires.ext.context;

import com.domwires.ext.context.mock.BaseMockContext.IMockModel;
import com.domwires.core.factory.AppFactory;
import com.domwires.ext.context.mock.BaseMockContext.IChildMockContext;
import com.domwires.ext.context.mock.BaseMockContext.IMainMockContext;
import com.domwires.ext.context.mock.BaseMockContext.IMockModelImmutable;
import utest.Assert;
import utest.Test;

class AppContextTest extends Test
{
    public function setup():Void
    {
    }

    public function teardown():Void
    {
    }

    public function testCreateMainContextWithChildContext():Void
    {
        var mainContext:IMainMockContext = new AppFactory().getInstance(IMainMockContext);
        var childContext:IChildMockContext = mainContext.getChildContext();
        var model:IMockModel = childContext.getModel();
        var model_2:IMockModel = childContext.getModel_2();

        //instantiated
        Assert.notNull(mainContext.getContextFactory());
        Assert.notNull(mainContext.getModelFactory());
        Assert.notNull(mainContext.getMediatorFactory());
        Assert.notNull(mainContext.getViewFactory());

        //injected from main context
        Assert.notNull(childContext.getContextFactory());
        Assert.notNull(childContext.getModelFactory());
        Assert.notNull(childContext.getMediatorFactory());
        Assert.notNull(childContext.getViewFactory());

        Assert.isNull(model.getContextFactory());
        Assert.notNull(model.getModelFactory());
        Assert.isNull(model.getMediatorFactory());
        Assert.isNull(model.getViewFactory());

        Assert.notEquals(mainContext.getFactory(), childContext.getFactory());
        Assert.equals(mainContext.getContextFactory(), childContext.getContextFactory());
        Assert.equals(mainContext.getModelFactory(), childContext.getModelFactory());
        Assert.equals(mainContext.getMediatorFactory(), childContext.getMediatorFactory());
        Assert.equals(mainContext.getViewFactory(), childContext.getViewFactory());
        Assert.equals(mainContext.getModelFactory(), model.getModelFactory());
        Assert.equals(childContext.getModel(), childContext.getModel_2());

        Assert.isFalse(childContext.parent == mainContext);
        Assert.isFalse(model.parent == childContext);

        mainContext.add(childContext);
        childContext.add(model);

        Assert.isTrue(childContext.parent == mainContext);
        Assert.isTrue(model.parent == childContext);

        mainContext.remove(childContext);
        childContext.remove(model);

        Assert.isFalse(childContext.parent == mainContext);
        Assert.isFalse(model.parent == childContext);
    }
}