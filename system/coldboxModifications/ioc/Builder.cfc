/**
 * We are overriding the buildCFC method here just so that we can stop Wirebox
 * from catching errors and rethrowing them in an unhelpful way
 *
 */
component extends="coldbox.system.ioc.Builder" {

	/**
	 * ColdBox 6.0 renamed Provider.get() to Provider.$get().
	 * Override to use Preside's Provider shim that restores get().
	 */
	private any function getProviderDSL( required definition, targetObject="", targetID ) {
		var thisType     = arguments.definition.dsl;
		var thisTypeLen  = listLen( thisType, ":" );
		var providerName = "";

		switch ( thisTypeLen ) {
			case 1: { providerName = arguments.definition.name; break; }
			case 2: { providerName = getToken( thisType, 2, ":" ); break; }
			default: { providerName = replaceNoCase( thisType, "provider:", "" ); }
		}

		var args = {
			  scopeRegistration : variables.injector.getScopeRegistration()
			, scopeStorage      : variables.injector.getScopeStorage()
			, targetObject      : arguments.targetObject
		};

		if ( variables.injector.containsInstance( providerName ) ) {
			args.name = providerName;
		} else {
			args.dsl = providerName;
		}

		return new preside.system.coldboxModifications.ioc.Provider( argumentCollection=args );
	}

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