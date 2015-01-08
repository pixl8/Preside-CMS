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

	public any function getProviderDsl( required struct definition, any targetObject ) output=false {
		var thisType 		= arguments.definition.dsl;
		var thisTypeLen 	= ListLen( thisType, ":" );
		var providerName 	= "";
		var args			= {};

		// DSL stages
		switch( thisTypeLen ){
			// provider default, get name of the provider from property
			case 1: { providerName = arguments.definition.name; break; }
			// provider:{name} stage
			case 2: { providerName = getToken(thisType,2,":"); break; }
			// multiple stages then most likely it is a full DSL being used
			default : {
				providerName = replaceNoCase( thisType, "provider:", "" );
			}
		}

		// Build provider arguments
		args = {
			  injector     = instance.injector
			, targetObject = arguments.targetObject
		};

		// Check if the passed in provider is an ID directly
		if( instance.injector.containsInstance( providerName ) ){
			args.name = providerName;
		}
		// Else try to tag it by FULL DSL
		else{
			args.dsl = providerName;
		}

		// Build provider and return it.
		return CreateObject( "component","preside.system.coldboxModifications.ioc.Provider" ).init( argumentCollection=args );
	}
}