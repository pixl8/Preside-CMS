/**
 * We are overriding the configure method here just so that we can load our custom Builder
 * (which we are overriding to stop Wirebox from trapping errors which obfuscates their origin)
 *
 */
component output=false extends="coldbox.system.ioc.Injector" {

	public any function configure( required any binder, required any properties ) output=false {
		var key         = "";
		var iData       = {};
		var withColdbox = isColdBoxLinked();

		lock name=instance.lockName type="exclusive" timeout=30 throwontimeout=true {
			if( withColdBox ){
				// link LogBox
				instance.logBox  = instance.coldbox.getLogBox();
				// Configure Logging for this injector
				instance.log = instance.logBox.getLogger( this );
				// Link CacheBox
				instance.cacheBox = instance.coldbox.getCacheBox();
				// Link Event Manager
				instance.eventManager = instance.coldbox.getInterceptorService();
			}

			// Store binder object built accordingly to our binder building procedures
			instance.binder = buildBinder( arguments.binder, arguments.properties );

			// Create local cache, logging and event management if not coldbox context linked.
			if( NOT withColdbox ){
				// Running standalone, so create our own logging first
				configureLogBox( instance.binder.getLogBoxConfig() );
				// Create local CacheBox reference
				configureCacheBox( instance.binder.getCacheBoxConfig() );
			}
			// Create and Configure Event Manager
			configureEventManager();

			// Register All Custom Listeners
			registerListeners();

			// Create our object builder
			instance.builder = createObject( "component", "preside.system.coldboxModifications.ioc.Builder" ).init( this );
			// Register Custom DSL Builders
			instance.builder.registerCustomBuilders();

			// Register Life Cycle Scopes
			registerScopes();

			// Parent Injector declared
			if( isObject(instance.binder.getParentInjector()) ){
				setParent( instance.binder.getParentInjector() );
			}

			// Scope registration if enabled?
			if( instance.binder.getScopeRegistration().enabled ){
				doScopeRegistration();
			}

			// process mappings for metadata and initialization.
			instance.binder.processMappings();

			// Announce To Listeners we are online
			iData.injector = this;
			instance.eventManager.processState("afterInjectorConfiguration",iData);
		}
	}

	public void function shutdownSingletons( boolean force=false ) {
		var singletons = instance.scopes["SINGLETON"].getSingletons();

		for( var singletonKey in singletons ) {
			var singleton = singletons[ singletonKey ];

			if ( IsObject( singleton ) && StructKeyExists( singleton, "shutdown" ) ) {
				singleton.shutdown( force=arguments.force );
			}
		}
	}

}