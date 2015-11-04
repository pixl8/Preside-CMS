/**
 * We are overriding the buildCFC method here just so that we can stop Wirebox
 * from catching errors and rethrowing them in an unhelpful way
 *
 */
component output=false extends="coldbox.system.ioc.Builder" {

	public any function buildCfc( required any mapping, struct initArguments={} ) output=false {
		var thisMap         = arguments.mapping;
		var oModel          = CreateObject( "component", thisMap.getPath() );
		var constructorArgs = "";
		var viMapping       = "";

		// Do we have virtual inheritance?
		if( arguments.mapping.isVirtualInheritance() ){
			// retrieve the VI mapping.
			viMapping = instance.injector.getBinder().getMapping( arguments.mapping.getVirtualInheritance() );
			// Does it match the family already?
			if( NOT isInstanceOf(oModel, viMapping.getPath() ) ){
				toVirtualInheritance( viMapping, oModel );
			}
		}

		if ( thisMap.isAutoInit() && StructKeyExists( oModel, thisMap.getConstructor() ) ) {
			constructorArgs = buildArgumentCollection( thisMap, thisMap.getDIConstructorArguments(), oModel );

			if ( !StructIsEmpty( arguments.initArguments ) ) {
				StructAppend( constructorArgs, arguments.initArguments, true );
			}

			oModel[ thisMap.getConstructor() ]( argumentCollection=constructorArgs );
		}

		return oModel;
	}
}