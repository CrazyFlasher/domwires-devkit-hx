package com.domwires.ext.context;

import com.domwires.core.factory.IAppFactoryImmutable;
import com.domwires.core.mvc.context.IContext;
import hex.di.ClassRef;
import hex.di.MappingName;
import com.domwires.ext.context.AppContext;

interface IAppContext extends IAppContextImmutable extends IContext
{
    function getInstance<T>(factory:IAppFactoryImmutable, type:ClassRef<T>, immutableType:Class<Dynamic>, ?name:MappingName):T;
}
