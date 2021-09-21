package com.domwires.ext.context.mock;

import com.domwires.core.factory.IAppFactoryImmutable;
import com.domwires.core.mvc.model.AbstractModel;
import com.domwires.core.mvc.model.IModel;
import com.domwires.core.mvc.model.IModelImmutable;
import com.domwires.ext.context.AppContext;

class MainMockContext extends BaseMockContext implements IMainMockContext
{
    private var childContext:IChildMockContext;

    override private function init():Void
    {
        super.init();

        childContext = getInstance(contextFactory, IChildMockContext, IChildMockContextImmutable);
    }

    public function getChildContext():IChildMockContext
    {
        return childContext;
    }
}

class ChildMockContext extends BaseMockContext implements IChildMockContext
{
    private var model:IMockModel;
    private var model_2:IMockModel;

    override private function init():Void
    {
        super.init();

        model = getInstance(modelFactory, IMockModel, IMockModelImmutable);
        model_2 = getInstance(contextFactory, IMockModel, IMockModelImmutable);
    }

    public function getModel():IMockModel
    {
        return model;
    }

    public function getModel_2():IMockModel
    {
        return model_2;
    }
}

class BaseMockContext extends AppContext implements IBaseMockContext
{
    public function getModelFactory():IAppFactoryImmutable
    {
        return modelFactory;
    }

    public function getContextFactory():IAppFactoryImmutable
    {
        return contextFactory;
    }

    public function getMediatorFactory():IAppFactoryImmutable
    {
        return mediatorFactory;
    }

    public function getViewFactory():IAppFactoryImmutable
    {
        return viewFactory;
    }

    public function getFactory():IAppFactoryImmutable
    {
        return factory;
    }
}

class MockModel extends AbstractModel implements IMockModel
{
    @Inject("modelFactory")
    private var modelFactory:IAppFactoryImmutable;

    @Inject("contextFactory") @Optional
    private var contextFactory:IAppFactoryImmutable;

    @Inject("mediatorFactory") @Optional
    private var mediatorFactory:IAppFactoryImmutable;

    @Inject("viewFactory") @Optional
    private var viewFactory:IAppFactoryImmutable;

    public function getModelFactory():IAppFactoryImmutable
    {
        return modelFactory;
    }

    public function getContextFactory():IAppFactoryImmutable
    {
        return contextFactory;
    }

    public function getMediatorFactory():IAppFactoryImmutable
    {
        return mediatorFactory;
    }

    public function getViewFactory():IAppFactoryImmutable
    {
        return viewFactory;
    }
}

interface IMainMockContext extends IMainMockContextImmutable extends IBaseMockContext
{
    function getChildContext():IChildMockContext;
}

interface IMainMockContextImmutable extends IBaseMockContextImmutable {}

interface IChildMockContext extends IChildMockContextImmutable extends IBaseMockContext
{
    function getModel():IMockModel;
    function getModel_2():IMockModel;
}

interface IChildMockContextImmutable extends IBaseMockContextImmutable {}

interface IBaseMockContext extends IBaseMockContextImmutable extends IAppContext {}
interface IBaseMockContextImmutable extends IAppContextImmutable
{
    function getModelFactory():IAppFactoryImmutable;
    function getContextFactory():IAppFactoryImmutable;
    function getMediatorFactory():IAppFactoryImmutable;
    function getViewFactory():IAppFactoryImmutable;
    function getFactory():IAppFactoryImmutable;
}

interface IMockModel extends IMockModelImmutable extends IModel {}
interface IMockModelImmutable extends IModelImmutable
{
    function getModelFactory():IAppFactoryImmutable;
    function getContextFactory():IAppFactoryImmutable;
    function getMediatorFactory():IAppFactoryImmutable;
    function getViewFactory():IAppFactoryImmutable;
}

