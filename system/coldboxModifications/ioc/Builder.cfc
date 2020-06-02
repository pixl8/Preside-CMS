/**
 * We are overriding the buildCFC method here just so that we can stop Wirebox
 * from catching errors and rethrowing them in an unhelpful way
 *
 */
component extends="coldbox.system.ioc.Builder" {

	public any function buildCfc( required any mapping, struct initArguments={} ) {
		var thisMap 	= arguments.mapping;
		var oModel 		= createObject( "component", thisMap.getPath() );

		// Do we have virtual inheritance?
		if( arguments.mapping.isVirtualInheritance() ){
			// retrieve the VI mapping.
			var viMapping = variables.injector.getBinder().getMapping( arguments.mapping.getVirtualInheritance() );
			// Does it match the family already?
			if( NOT isInstanceOf( oModel, viMapping.getPath() ) ){
				// Virtualize it.
				toVirtualInheritance( viMapping, oModel, arguments.mapping );
			}
		}

		// Constructor initialization?
		if( thisMap.isAutoInit() AND structKeyExists( oModel, thisMap.getConstructor() ) ){
			// Get Arguments
			var constructorArgs = buildArgumentCollection( thisMap, thisMap.getDIConstructorArguments(), oModel );

			// Do We have initArguments to override
			if( NOT structIsEmpty( arguments.initArguments ) ){
				structAppend( constructorArgs, arguments.initArguments, true );
			}

			// Invoke constructor
			invoke( oModel, thisMap.getConstructor(), constructorArgs );
		}

		return oModel;
	}
}