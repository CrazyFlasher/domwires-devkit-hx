package com.domwires.ext.context;

import com.domwires.core.mvc.context.IContext;
import com.domwires.core.factory.IAppFactoryImmutable;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.core.mvc.context.AbstractContext;
import com.domwires.core.mvc.hierarchy.IHierarchyObject;
import com.domwires.core.mvc.mediator.IMediator;
import com.domwires.core.mvc.mediator.IMediatorContainer;
import com.domwires.core.mvc.model.IModel;
import com.domwires.core.mvc.model.IModelContainer;
import hex.di.ClassRef;
import hex.di.MappingName;

class AppContext extends AbstractContext implements IAppContext
{
    private final ADD_ERROR:String = "Use 'add' method instead";
    private final REMOVE_ERROR:String = "Use 'remove' method instead";

    @Inject("mediatorFactory") @Optional
    private var mediatorFactory:IAppFactory;

    @Inject("viewFactory") @Optional
    private var viewFactory:IAppFactory;

    @Inject("modelFactory") @Optional
    private var modelFactory:IAppFactory;

    @Inject("contextFactory") @Optional
    private var contextFactory:IAppFactory;

    override private function init():Void
    {
        super.init();

        if (contextFactory == null)
        {
            createFactories();
        }
    }

    private function createFactories():Void
    {
        viewFactory = new AppFactory();
        mediatorFactory = new AppFactory();
        modelFactory = new AppFactory();
        contextFactory = new AppFactory();

        contextFactory.mapToValue(IAppFactory, mediatorFactory, "mediatorFactory");
        contextFactory.mapToValue(IAppFactory, viewFactory, "viewFactory");
        contextFactory.mapToValue(IAppFactory, modelFactory, "modelFactory");
        contextFactory.mapToValue(IAppFactory, contextFactory, "contextFactory");

        modelFactory.mapToValue(IAppFactoryImmutable, modelFactory, "modelFactory");

        mediatorFactory.mapToValue(IAppFactoryImmutable, viewFactory, "viewFactory");
    }

    override public function add(child:IHierarchyObject, index:Int = -1):Bool
    {
        if (Std.isOfType(child, IModelContainer) || Std.isOfType(child, IMediatorContainer))
        {
            return super.add(child, index);
        }

        var success:Bool = false;

        if (Std.isOfType(child, IModel))
        {
            success = !modelContainer.contains(child);
            super.addModel(cast child);
        } else
        if (Std.isOfType(child, IMediator))
        {
            success = !mediatorContainer.contains(child);
            super.addMediator(cast child);
        }

        return success;
    }

    override public function remove(child:IHierarchyObject, dispose:Bool = false):Bool
    {
        if (Std.isOfType(child, IModelContainer) || Std.isOfType(child, IMediatorContainer))
        {
            return super.remove(child, dispose);
        }

        var success:Bool = false;

        if (Std.isOfType(child, IModel))
        {
            success = !modelContainer.contains(child);
            super.removeModel(cast child);
        } else
        if (Std.isOfType(child, IMediator))
        {
            success = !mediatorContainer.contains(child);
            super.removeMediator(cast child);
        }

        return success;
    }

    override public function addModel(model:IModel):IModelContainer
    {
        throw ADD_ERROR;
    }

    override public function addMediator(mediator:IMediator):IMediatorContainer
    {
        throw ADD_ERROR;
    }

    override public function removeModel(model:IModel, dispose:Bool = false):IModelContainer
    {
        throw REMOVE_ERROR;
    }

    override public function removeMediator(mediator:IMediator, dispose:Bool = false):IMediatorContainer
    {
        throw REMOVE_ERROR;
    }

    public function getInstance<T>(factory:IAppFactoryImmutable, type:ClassRef<T>, immutableType:Class<Dynamic>, ?name:MappingName):T
    {
        var instance:T = factory.getInstance(type, name);

        if (Std.isOfType(instance, IContext))
        {
            contextFactory.mapToValue(immutableType, instance, name);
        } else
        if (Std.isOfType(instance, IModel))
        {
            contextFactory.mapToValue(type, instance, name);
            mediatorFactory.mapToValue(immutableType, instance, name);
            modelFactory.mapToValue(immutableType, instance, name);
            this.factory.mapToValue(type, instance, name);
        } else
        if (Std.isOfType(instance, IMediator))
        {
            contextFactory.mapToValue(type, instance, name);
        }

        return instance;
    }
}
