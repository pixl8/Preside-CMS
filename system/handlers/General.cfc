component {
	property name="applicationReloadService"      inject="applicationReloadService";
	property name="databaseMigrationService"      inject="databaseMigrationService";
	property name="applicationsService"           inject="applicationsService";
	property name="websiteLoginService"           inject="websiteLoginService";
	property name="adminLoginService"             inject="loginService";
	property name="antiSamySettings"              inject="coldbox:setting:antiSamy";
	property name="antiSamyService"               inject="delayedInjector:antiSamyService";
	property name="presideTaskmanagerHeartBeat"   inject="presideTaskmanagerHeartBeat";
	property name="cacheboxReapHeartBeat"         inject="cacheboxReapHeartBeat";
	property name="presideAdhocTaskHeartBeat"     inject="presideAdhocTaskHeartBeat";
	property name="healthcheckService"            inject="healthcheckService";
	property name="permissionService"             inject="permissionService";
	property name="emailQueueConcurrency"         inject="coldbox:setting:email.queueConcurrency";
	property name="assetQueueConcurrency"         inject="coldbox:setting:assetManager.queue.concurrency";
	property name="presideObjectService"          inject="delayedInjector:presideObjectService";
	property name="presideFieldRuleGenerator"     inject="delayedInjector:presideFieldRuleGenerator";
	property name="configuredValidationProviders" inject="coldbox:setting:validationProviders";
	property name="validationEngine"              inject="validationEngine";

	public void function applicationStart( event, rc, prc ) {
		prc._presideReloaded = true;

		_performDbMigrations();
		_configureVariousServices();
		_populateDefaultLanguages();
		_setupCatchAllAdminUserGroup();
		_startHeartbeats();
		_setupValidators();

		announceInterception( "onApplicationStart" );
	}

	public void function applicationEnd( event, rc, prc ) {
		applicationReloadService.gracefulShutdown(
			force = StructKeyExists( url, "force" )
		);
	}

	public void function requestStart( event, rc, prc ) {
		_xssProtect( argumentCollection = arguments );
		_reloadChecks( argumentCollection = arguments );
		_recordUserVisits( argumentCollection = arguments );
	}

	public void function notFound( event, rc, prc ) {
		var notFoundViewlet = getSetting( name="notFoundViewlet", defaultValue="errors.notFound" );
		var notFoundLayout  = "";

		if ( event.isAdminRequest() ) {
			var activeApplication = applicationsService.getActiveApplication( event.getCurrentEvent() );

			notFoundLayout = applicationsService.getLayout( activeApplication );
		} else {
			notFoundLayout  = getSetting( name="notFoundLayout" , defaultValue="Main" );
		}

		event.setLayout( notFoundLayout );
		event.setView( view="/core/simpleBodyRenderer" );

		rc.body = renderViewlet( event=notFoundViewlet );
	}

	private void function accessDenied( event, rc, prc, args={} ) {
		var accessDeniedViewlet = getSetting( name="accessDeniedViewlet", defaultValue="errors.accessDenied" );
		var accessDeniedLayout  = getSetting( name="accessDeniedLayout" , defaultValue="Main" );

		event.setLayout( accessDeniedLayout );
		event.setView( view="/core/simpleBodyRenderer" );

		rc.body = renderViewlet( event=accessDeniedViewlet, args=args );
	}

// private helpers
	private void function _xssProtect( event, rc, prc ) {
		if ( IsTrue( antiSamySettings.enabled ?: "" ) ) {
			var adminBypass = IsTrue( antiSamySettings.bypassForAdministrators ?: "" );
			var bypass      = adminBypass && ( event.isAdminUser() || event.isAdminRequest() );

			if ( !bypass ) {
				var policy = antiSamySettings.policy ?: "myspace";

				for( var key in rc ){
					if( IsSimpleValue( rc[ key ] ) ) {
						rc[ key ] = antiSamyService.clean( rc[ key ], policy );
					}
				}
			}

			request[ "preside.path_info"    ] = antiSamyService.clean( request[ "preside.path_info"    ] ?: "" );
			request[ "preside.query_string" ] = antiSamyService.clean( request[ "preside.query_string" ] ?: "" );
		}
	}

	private void function _reloadChecks( event, rc, prc ) {
		var anythingReloaded = false;

		if ( _requestIsExcludedFromReload( argumentCollection=arguments ) ) {
			return;
		}

		var reloadPassword = getSetting( name="reinitPassword", defaultValue="true" );
		var devSettings    = getSetting( name="developerMode" , defaultValue=false );

		if ( IsBoolean( devSettings ) ) {
			devSettings = {
				  dbSync               = devSettings
				, flushCaches          = devSettings
				, reloadForms          = devSettings
				, reloadI18n           = devSettings
				, reloadPresideObjects = devSettings
				, reloadWidgets        = devSettings
				, reloadPageTypes      = devSettings
				, reloadStatic         = devSettings
			};
		} else {
			devSettings = {
				  dbSync               = IsBoolean( devSettings.dbSync               ?: "" ) and devSettings.dbSync
				, flushCaches          = IsBoolean( devSettings.flushCaches          ?: "" ) and devSettings.flushCaches
				, reloadForms          = IsBoolean( devSettings.reloadForms          ?: "" ) and devSettings.reloadForms
				, reloadI18n           = IsBoolean( devSettings.reloadI18n           ?: "" ) and devSettings.reloadI18n
				, reloadPresideObjects = IsBoolean( devSettings.reloadPresideObjects ?: "" ) and devSettings.reloadPresideObjects
				, reloadWidgets        = IsBoolean( devSettings.reloadWidgets        ?: "" ) and devSettings.reloadWidgets
				, reloadPageTypes      = IsBoolean( devSettings.reloadPageTypes      ?: "" ) and devSettings.reloadPageTypes
				, reloadStatic         = IsBoolean( devSettings.reloadStatic         ?: "" ) and devSettings.reloadStatic
			};
		}

		lock type="exclusive" timeout="10" name="#Hash( ExpandPath( '/' ) )#-application-reloads" {
			if ( devSettings.flushCaches or ( event.valueExists( "fwReinitCaches" ) and Hash( rc.fwReinitCaches ) eq reloadPassword ) ) {
				applicationReloadService.clearCaches();
				anythingReloaded = true;
			}

			if ( devSettings.dbSync or ( event.valueExists( "fwReinitDbSync" ) and Hash( rc.fwReinitDbSync ) eq reloadPassword ) ) {
				applicationReloadService.reloadPresideObjects();
				applicationReloadService.dbSync();
				anythingReloaded = true;
			} else if ( devSettings.reloadPresideObjects or ( event.valueExists( "fwReinitObjects" ) and Hash( rc.fwReinitObjects ) eq reloadPassword ) ) {
				applicationReloadService.reloadPresideObjects();
				anythingReloaded = true;
			}

			if ( devSettings.reloadWidgets or ( event.valueExists( "fwReinitWidgets" ) and Hash( rc.fwReinitWidgets ) eq reloadPassword ) ) {
				applicationReloadService.reloadWidgets();
				anythingReloaded = true;
			}

			if ( devSettings.reloadPageTypes or ( event.valueExists( "fwReinitPageTypes" ) and Hash( rc.fwReinitPageTypes ) eq reloadPassword ) ) {
				applicationReloadService.reloadPageTypes();
				anythingReloaded = true;
			}

			if ( devSettings.reloadForms  or ( event.valueExists( "fwReinitForms" ) and Hash( rc.fwReinitForms ) eq reloadPassword ) ) {
				applicationReloadService.reloadForms();
				anythingReloaded = true;
			}

			if ( devSettings.reloadI18n or ( event.valueExists( "fwReinitI18n" ) and Hash( rc.fwReinitI18n ) eq reloadPassword ) ) {
				applicationReloadService.reloadI18n();
				anythingReloaded = true;
			}

			if ( devSettings.reloadStatic or ( event.valueExists( "fwReinitStatic" ) and Hash( rc.fwReinitStatic ) eq reloadPassword ) ) {
				applicationReloadService.reloadStatic();
				anythingReloaded = true;
			}
		}
	}

	private boolean function _requestIsExcludedFromReload( event, rc, prc ) {
		if ( prc._presideReloaded ?: false ) {
			return true;
		}

		if ( event.isAjax() ) {
			return true;
		}

		if ( ReFindNoCase( "^(assetDownload|ajaxproxy|staticAssetDownload)", event.getCurrentHandler() ) ) {
			return true;
		}

		return false;
	}

	private void function _recordUserVisits( event, rc, prc ) {
		if ( !event.isAjax() && !ReFindNoCase( "^(assetDownload|ajaxproxy|staticAssetDownload)", event.getCurrentHandler() ) ) {
			websiteLoginService.recordVisit();
			adminLoginService.recordVisit();
		}
	}

	private void function _performDbMigrations() {
		databaseMigrationService.migrate();
	}

	private void function _populateDefaultLanguages() {
		if ( isFeatureEnabled( "multilingual" ) ) {
			getModel( "multilingualPresideObjectService" ).populateCoreLanguageSet();
		}
	}

	private void function _configureVariousServices() {
		var i18n = getModel( "i18n" );

		i18n.configure();

		if ( Len( Trim( request.DefaultLocaleFromCookie ?: "" ) ) ) {
			i18n.setFwLocale( request.DefaultLocaleFromCookie );
		}
	}

	private void function _startHeartbeats() {
		if ( isFeatureEnabled( "emailQueueHeartBeat" ) ) {
			for( var i=1; i<=emailQueueConcurrency; i++ ) {
				getModel( "PresideEmailQueueHeartBeat#i#" ).start();
			}
		}

		if ( isFeatureEnabled( "healthchecks" ) ) {
			for( var serviceId in healthcheckService.listRegisteredServices() ) {
				getModel( "healthCheckHeartbeat#serviceId#" ).start();
			}
		}

		if ( isFeatureEnabled( "adhocTaskHeartBeat" ) ) {
			presideAdhocTaskHeartBeat.start();
		}

		if ( isFeatureEnabled( "taskmanagerHeartBeat" ) ) {
			presideTaskmanagerHeartBeat.start();
		}

		if ( isFeatureEnabled( "assetQueue" ) && isFeatureEnabled( "assetQueueHeartBeat" ) ) {
			for( var i=1; i<=assetQueueConcurrency; i++ ) {
				getModel( "AssetQueueHeartBeat#i#" ).start();
			}
		}

		cacheboxReapHeartBeat.start();
	}

	private void function _setupCatchAllAdminUserGroup() {
		permissionService.setupCatchAllGroup();
	}

	private void function _setupValidators() {
		if ( IsArray( configuredValidationProviders ) ) {
			for ( var providerName in configuredValidationProviders ) {
				validationEngine.newProvider( getModel( dsl=providerName ) );
			}
		}

		for( var objName in presideObjectService.listObjects( includeGeneratedObjects=true ) ) {
			var obj = presideObjectService.getObject( objName );
			if ( not IsSimpleValue( obj ) ) {
				validationEngine.newProvider( obj );
			}

			var rules = presideFieldRuleGenerator.generateRulesFromPresideObject( objName );
			validationEngine.newRuleset( name="PresideObject.#objName#", rules=rules );
		}
	}
}