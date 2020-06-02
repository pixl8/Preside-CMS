/**
 * We are overriding the configure method here so that:
 *
 * 1) we can load our custom Builder (which we are overriding to stop Wirebox from trapping errors which obfuscates their origin)
 * 2) we can add a graceful shutdown process for all singletons
 *
 */
component extends="coldbox.system.ioc.Injector" {

	/**
	 * Configure this injector for operation, called by the init(). You can also re-configure this injector programmatically, but it is not recommended.
	 *
	 * @binder The configuration binder object or path to configure this Injector instance with
	 * @binder.doc_generic coldbox.system.ioc.config.Binder
	 * @properties A structure of binding properties to passthrough to the Configuration CFC
	 * @properties.doc_generic struct
	 **/
	Injector function configure( required binder, required struct properties ){
		var iData			= {};
		var withColdbox 	= isColdBoxLinked();

		// Lock For Configuration
		lock name=variables.lockName type="exclusive" timeout="30" throwontimeout="true"{
			if( withColdBox ){
				// link LogBox
				variables.logBox  = variables.coldbox.getLogBox();
				// Configure Logging for this injector
				variables.log = variables.logBox.getLogger( this );
				// Link CacheBox
				variables.cacheBox = variables.coldbox.getCacheBox();
				// Link Event Manager
				variables.eventManager = variables.coldbox.getInterceptorService();
			}

			// Create and Configure Event Manager
			configureEventManager();

			// Store binder object built accordingly to our binder building procedures
			variables.binder = buildBinder( arguments.binder, arguments.properties );

			// Create local cache, logging and event management if not coldbox context linked.
			if( NOT withColdbox ){
				// Running standalone, so create our own logging first
				configureLogBox( variables.binder.getLogBoxConfig() );
				// Create local CacheBox reference
				configureCacheBox( variables.binder.getCacheBoxConfig() );
			}

			// Register All Custom Listeners
			registerListeners();
			// Create our object builder
			variables.builder = new preside.system.coldboxModifications.ioc.Builder( this );
			// Register Custom DSL Builders
			variables.builder.registerCustomBuilders();
			// Register Life Cycle Scopes
			registerScopes();
			// Parent Injector declared
			if( isObject( variables.binder.getParentInjector() ) ){
				setParent( variables.binder.getParentInjector() );
			}

			// Scope registration if enabled?
			if( variables.binder.getScopeRegistration().enabled ){
				doScopeRegistration();
			}

			// Register binder as an interceptor
			if( NOT isColdBoxLinked() ){
				variables.eventManager.register( variables.binder, "wirebox-binder" );
			} else {
				variables.eventManager.registerInterceptor( interceptorObject=variables.binder, interceptorName="wirebox-binder" );
			}

			// Check if binder has onLoad convention
			if( structKeyExists( variables.binder, "onLoad" ) ){
				variables.binder.onLoad();
			}

			// process mappings for metadata and initialization.
			variables.binder.processMappings();

			// Announce To Listeners we are online
			iData.injector = this;
			variables.eventManager.processState( "afterInjectorConfiguration", iData );
		}

		return this;
	}


	public void function shutdownSingletons( boolean force=false ) {
		var singletons = variables.scopes["SINGLETON"].getSingletons();

		for( var singletonKey in singletons ) {
			var singleton = singletons[ singletonKey ];

			if ( IsObject( singleton ) && StructKeyExists( singleton, "canShutdown" ) ) {
				if ( !singleton.canShutdown( force=arguments.force ) ) {
					throw(
						  type    = "preside.reload.failed"
						, message = "The application has been prevented from reloading because one or more services refused to shutdown."
						, detail  = "Either: reload the application with the &force URL parameter; restart the server; or, wait until later."
					);
				}
			}
		}

		for( var singletonKey in singletons ) {
			var singleton = singletons[ singletonKey ];

			if ( IsObject( singleton ) && StructKeyExists( singleton, "shutdown" ) ) {
				singleton.shutdown();
			}
		}
	}

}