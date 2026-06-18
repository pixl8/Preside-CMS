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

		return new preside.system.coldboxModifications.ioc.Provider(
			  scopeRegistration : variables.injector.getScopeRegistration()
			, targetObject      : arguments.targetObject
			, name              : providerName
			, injectorName      : variables.injector.getName()
		);
	}

	public any function buildCfc( required any mapping, struct initArguments={} ) {
		var thisMap 	= arguments.mapping;
		var oModel 		= createObject( "component", thisMap.getPath() );

		// CB 7.0: FrameworkSupertype.init() sets variables.cbInjectedHelpers but
		// some Preside components extend FrameworkSupertype without calling super.init().
		// Use WireBox's utility to inject it into the target's variables scope.
		if ( StructKeyExists( oModel, "loadApplicationHelpers" ) ) {
			variables.utility.getMixerUtil().start( oModel );
			oModel.injectPropertyMixin( "cbInjectedHelpers", {} );
			variables.utility.getMixerUtil().stop( oModel );
		}

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