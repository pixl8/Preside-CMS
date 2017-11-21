component extends="coldbox.system.web.services.ModuleService" output=false {

	public any function activateModule( required string moduleName ) {
		var modules 			= controller.getSetting( "modules" );
		var iData       		= {};
		var interceptorService  = controller.getInterceptorService();
		var wirebox				= controller.getWireBox();

		// If module not registered, throw exception
		if( NOT structKeyExists( modules, arguments.moduleName ) ){
			throw(
				message = "Cannot activate module: #arguments.moduleName#",
				detail 	= "The module has not been registered, register the module first and then activate it.",
				type 	= "ModuleService.IllegalModuleState"
			);
		}

		// Check if module already activated
		if( modules[ arguments.moduleName ].activated ){
			// Log it
			if( instance.logger.canDebug() ){
				instance.logger.debug( "Module #arguments.moduleName# already activated, skipping activation." );
			}
			return this;
		}

		// Check if module CAN be activated
		if( !modules[ arguments.moduleName ].activate ){
			// Log it
			if( instance.logger.canDebug() ){
				instance.logger.debug( "Module #arguments.moduleName# cannot be activated as it is flagged to not activate, skipping activation." );
			}
			return this;
		}

		// Get module settings
		var mConfig = modules[ arguments.moduleName ];

		// Do we have dependencies to activate first
		for( var thisDependency in mConfig.dependencies ){
			if( instance.logger.canDebug() ){
				instance.logger.debug( "Activating #arguments.moduleName# requests dependency activation: #thisDependency#" );
			}
			// Activate dependency first
			activateModule( thisDependency );
		}

		// lock and load baby
		lock 	name="module.#getController().getAppHash()#.activation.#arguments.moduleName#"
				type="exclusive"
				timeout="20"
				throwontimeout="true"
		{

			// preModuleLoad interception
			var iData = { moduleLocation=mConfig.path, moduleName=arguments.moduleName };
			interceptorService.processState( "preModuleLoad", iData );

			// Register handlers
			mConfig.registeredHandlers = controller.getHandlerService().getHandlerListing( mconfig.handlerPhysicalPath, mConfig.handlerInvocationPath ).reduce( function( value, handler ){
				return value.listAppend( handler.name );
			}, "" );

			// Register the Config as an observable also.
			interceptorService.registerInterceptor(
				interceptorObject 	= instance.mConfigCache[ arguments.moduleName ],
				interceptorName 	= "ModuleConfig:#arguments.moduleName#"
			);

			// Register Models if it exists
			if( directoryExists( mconfig.modelsPhysicalPath ) and mConfig.autoMapModels ){
				// Add as a mapped directory with module name as the namespace with correct mapping path
				var packagePath = ( len( mConfig.cfmapping ) ? mConfig.cfmapping & ".#mConfig.conventions.modelsLocation#" :  mConfig.modelsInvocationPath );
				if( len( mConfig.modelNamespace ) ){
					wirebox.getBinder().mapDirectory( packagePath=packagePath, namespace="@#mConfig.modelNamespace#" );
				} else {
					// just register with no namespace
					wirebox.getBinder().mapDirectory( packagePath=packagePath );
				}
				wirebox.getBinder().processMappings();
			}

			// Register Interceptors with Announcement service
			for( var y=1; y lte arrayLen( mConfig.interceptors ); y++ ){
				interceptorService.registerInterceptor(
					interceptorClass 		= mConfig.interceptors[ y ].class,
					interceptorProperties 	= mConfig.interceptors[ y ].properties,
					interceptorName 		= mConfig.interceptors[ y ].name
				);
				// Loop over module interceptors to autowire them
				wirebox.autowire(
					target 	= interceptorService.getInterceptor( mConfig.interceptors[ y ].name, true ),
					targetID= mConfig.interceptors[ y ].class
				);
			}

			// Register module routing entry point pre-pended to routes
			if( controller.settingExists( 'sesBaseURL' ) AND
				len( mConfig.entryPoint ) AND NOT
				find( ":", mConfig.entryPoint )
			){
				interceptorService.getInterceptor( "SES", true )
					.addModuleRoutes( pattern=mConfig.entryPoint, module=arguments.moduleName, append=false );
			}

			// Call on module configuration object onLoad() if found
			if( structKeyExists( instance.mConfigCache[ arguments.moduleName ], "onLoad" ) ){
				instance.mConfigCache[ arguments.moduleName ].onLoad();
			}

			// postModuleLoad interception
			iData = { moduleLocation=mConfig.path, moduleName=arguments.moduleName, moduleConfig=mConfig };
			interceptorService.processState( "postModuleLoad", iData );

			// Mark it as loaded as it is now activated
			mConfig.activated = true;

			// Now activate any children
			for( var thisChild in mConfig.childModules ){
				activateModule( moduleName=thisChild );
			}

			// Log it
			if( instance.logger.canDebug() ){
				instance.logger.debug( "Module #arguments.moduleName# activated sucessfully." );
			}

		} // end lock

		return this;
	}
}