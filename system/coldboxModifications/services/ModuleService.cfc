component extends="coldbox.system.web.services.ModuleService" output=false {

	ModuleService function activateModule( required moduleName ){
		var modules 			= controller.getSetting( "modules" );
		var interceptorService  = controller.getInterceptorService();
		var appRouter 			= variables.wirebox.getInstance( "router@coldbox" );

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
			if( variables.logger.canDebug() ){
				variables.logger.debug( "Module #arguments.moduleName# already activated, skipping activation." );
			}
			return this;
		}

		// Check if module CAN be activated
		if( !modules[ arguments.moduleName ].activate ){
			// Log it
			if( variables.logger.canDebug() ){
				variables.logger.debug( "Module #arguments.moduleName# cannot be activated as it is flagged to not activate, skipping activation." );
			}
			return this;
		}

		// Get module settings
		var mConfig = modules[ arguments.moduleName ];

		// Do we have dependencies to activate first
		mConfig.dependencies.each( function( thisDependency ){
			if( variables.logger.canDebug() ){
				variables.logger.debug( "Activating #moduleName# requests dependency activation: #thisDependency#" );
			}
			// Activate dependency first
			activateModule( thisDependency );
		} );

		// Check if activating one of this module's dependencies already activated this module
		if( modules[ arguments.moduleName ].activated ){
			// Log it
			if( variables.logger.canDebug() ){
				variables.logger.debug( "Module #arguments.moduleName# already activated during dependecy activation, skipping activation." );
			}
			return this;
		}

		// lock and load baby
		lock 	name="module#getController().getAppHash()#.activation.#arguments.moduleName#"
				type="exclusive"
				timeout="20"
				throwontimeout="true"
		{

			// preModuleLoad interception
			interceptorService.processState(
				"preModuleLoad",
				{
					moduleLocation = mConfig.path,
					moduleName     = arguments.moduleName
				}
			);

			// Register handlers
			mConfig.registeredHandlers = controller.getHandlerService().getHandlerListing( mconfig.handlerPhysicalPath, mConfig.handlerInvocationPath ).reduce( function( value, handler ){
				return value.listAppend( handler.name );
			}, "" );

			// Register the Config as an observable also.
			interceptorService.registerInterceptor(
				interceptorObject 	= variables.mConfigCache[ arguments.moduleName ],
				interceptorName 	= "ModuleConfig:#arguments.moduleName#"
			);

			// Register Models
			if( directoryExists( mconfig.modelsPhysicalPath ) and mConfig.autoMapModels ){

				// Add as a mapped directory with module name as the namespace with correct mapping path
				var packagePath = ( len( mConfig.cfmapping ) ? mConfig.cfmapping & ".#mConfig.conventions.modelsLocation#" :  mConfig.modelsInvocationPath );
				var binder 		= variables.wirebox.getBinder();

				if( len( mConfig.modelNamespace ) ){
					binder.mapDirectory( packagePath=packagePath, namespace="@#mConfig.modelNamespace#" );
				} else {
					// just register with no namespace
					binder.mapDirectory( packagePath=packagePath );
				}

				// Register Default Module Export if it exists as @moduleName, so you can do getInstance( "@moduleName" )
				if( fileExists( mconfig.modelsPhysicalPath & "/#arguments.moduleName#.cfc" ) ){
					binder.map( [ "@#arguments.moduleName#", "@#mConfig.modelNamespace#" ] )
						.to( packagePath & ".#arguments.moduleName#" );
 				}

				// Process mapped data
				binder.processMappings();
			}

			// Register Interceptors with Announcement service
			mConfig.interceptors.each( function( thisInterceptor ){
				interceptorService.registerInterceptor(
					interceptorClass 		= thisInterceptor.class,
					interceptorProperties 	= thisInterceptor.properties,
					interceptorName 		= thisInterceptor.name & "@" & moduleName
				);
				// Loop over module interceptors to autowire them
				variables.wirebox.autowire(
					target 	 = interceptorService.getInterceptor( thisInterceptor.name & "@" & moduleName ),
					targetID = thisInterceptor.class
				);
			} );

			// Register module routing entry point pre-pended to routes
			if( mConfig.entryPoint.len() ){
				var parentEntryPoint 		= "";
				var visitParentEntryPoint 	= function( parent ){
					var moduleConfig 	= modules[ arguments.parent ];
					var thisEntryPoint 	= reReplace( moduleConfig.entryPoint, "^/", "" );
					// Do we recurse?
					if( len( moduleConfig.parent ) ){
						return visitParentEntryPoint( moduleConfig.parent ) & "/" & thisEntryPoint;
					}
					return thisEntryPoint;
				};

				// Discover parent inherit mapping? if set to true and we actually have a parent
				if( mConfig.inheritEntryPoint && len( mConfig.parent ) ){
					parentEntryPoint = visitParentEntryPoint( mConfig.parent ) & "/";
				}

				// Store Inherited Entry Point
				mConfig.inheritedEntryPoint = parentEntryPoint & reReplace( mConfig.entryPoint, "^/", "" );

				// Register Module Routing Entry Point + Struct Literals for routes and resources
				appRouter.addModuleRoutes(
					pattern = mConfig.inheritedEntryPoint,
					module  = arguments.moduleName,
					append  = false
				);

				// Does the module have its own config.Router.cfc, if so, let's use it as well.
				if( fileExists( mConfig.routerPhysicalPath ) ){
					// Process as a Router.cfc with virtual inheritance
					wirebox.registerNewInstance( name=mConfig.routerInvocationPath, instancePath=mConfig.routerInvocationPath )
						.setVirtualInheritance( "coldbox.system.web.routing.Router" )
						.setThreadSafe( true );
					// Create the Router back into the config
					mConfig.router = wirebox.getInstance( mConfig.routerInvocationPath );
					// Process it
					mConfig.router.configure();
				}

				// Add convention based routing if it does not exist.
				var conventionsRouteExists = mConfig.router.getRoutes().find( function( item ){
					return ( item.pattern == "/:handler/:action?" || item.pattern == ":handler/:action?" );
				} );
				if( conventionsRouteExists == 0 ){
					mConfig.router.route( "/:handler/:action?" ).end();
				};

				// Process Module Router
				mConfig.router.getRoutes().each( function( item ){
					// Incorporate module context
					if( !item.module.len() ){
						item.module = moduleName;
					}
					// Add to App Router
					appRouter.getModuleRoutes( moduleName ).append( item );
				} );
			}

			// Register App and View Helpers
			if( arrayLen( mConfig.applicationHelper ) ){

				// Map the helpers with the right mapping if not starting with /
				mConfig.applicationHelper = mConfig.applicationHelper.map( function( item ){
					return ( reFind( "^/", item ) ? item : "#mConfig.mapping#/#item#" );
				} );

				// Incorporate into global helpers
				controller.getSetting( "applicationHelper" ).addAll( mConfig.applicationHelper );
			}

			// Call on module configuration object onLoad() if found
			if( structKeyExists( variables.mConfigCache[ arguments.moduleName ], "onLoad" ) ){
				variables.mConfigCache[ arguments.moduleName ].onLoad();
			}

			// postModuleLoad interception
			interceptorService.processState(
				"postModuleLoad",
				{
					moduleLocation = mConfig.path,
					moduleName     = arguments.moduleName,
					moduleConfig   = mConfig
				}
			);

			// Mark it as loaded as it is now activated
			mConfig.activated = true;

			// Now activate any children
			mConfig.childModules.each( function( thisChild ){
				activateModule( moduleName=thisChild );
			} );

			// Log it
			if( variables.logger.canDebug() ){
				variables.logger.debug( "Module #arguments.moduleName# activated sucessfully." );
			}

		} // end lock

		return this;
	}
}