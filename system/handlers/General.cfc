component {
	property name="applicationReloadService"      inject="delayedInjector:applicationReloadService";
	property name="coreDatabaseMigrationService"  inject="delayedInjector:coreDatabaseMigrationService";
	property name="appDatabaseMigrationService"   inject="delayedInjector:appDatabaseMigrationService";
	property name="applicationsService"           inject="delayedInjector:applicationsService";
	property name="websiteLoginService"           inject="delayedInjector:websiteLoginService";
	property name="adminLoginService"             inject="delayedInjector:loginService";
	property name="antiSamySettings"              inject="coldbox:setting:antiSamy";
	property name="antiSamyService"               inject="delayedInjector:antiSamyService";
	property name="presideTaskmanagerHeartBeat"   inject="delayedInjector:presideTaskmanagerHeartBeat";
	property name="presideSystemAlertsHeartBeat"  inject="delayedInjector:presideSystemAlertsHeartBeat";
	property name="cacheboxReapHeartBeat"         inject="delayedInjector:cacheboxReapHeartBeat";
	property name="presideAdhocTaskHeartBeat"     inject="delayedInjector:presideAdhocTaskHeartBeat";
	property name="presideSessionReapHeartbeat"   inject="delayedInjector:presideSessionReapHeartbeat";
	property name="scheduledExportHeartBeat"      inject="delayedInjector:scheduledExportHeartBeat";
	property name="segmentationFiltersHeartbeat"  inject="delayedInjector:segmentationFiltersHeartbeat";
	property name="healthcheckService"            inject="delayedInjector:healthcheckService";
	property name="permissionService"             inject="delayedInjector:permissionService";
	property name="dataExportTemplateService"     inject="delayedInjector:dataExportTemplateService";
	property name="emailQueueConcurrency"         inject="coldbox:setting:email.queueConcurrency";
	property name="assetQueueConcurrency"         inject="coldbox:setting:assetManager.queue.concurrency";
	property name="presideObjectService"          inject="presideObjectService";
	property name="presideFieldRuleGenerator"     inject="delayedInjector:presideFieldRuleGenerator";
	property name="configuredValidationProviders" inject="coldbox:setting:validationProviders";
	property name="coreValidationProviders"       inject="coldbox:setting:coreValidationProviders";
	property name="validationEngine"              inject="validationEngine";
	property name="systemAlertsService"           inject="delayedInjector:systemAlertsService";
	property name="emailTemplateService"          inject="delayedInjector:emailTemplateService";
	property name="systemEmailTemplateService"    inject="delayedInjector:systemEmailTemplateService";
	property name="IgnoreFileService"             inject="delayedInjector:IgnoreFileService";
	property name="formsService"                  inject="delayedInjector:formsService";

	public void function applicationStart( event, rc, prc ) {
		prc._presideReloaded = true;

		_configureVariousServices(); // important for this to happen first
		_populateDefaultLanguages();
		_setupCatchAllAdminUserGroup();
		_startHeartbeats();
		_setupValidators();
		_performDbMigrations();
		_setupEmailTemplating();
		_runSystemAlertChecks();
		_writeIgnoreFile();

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
		_setLocale( argumentCollection = arguments );
		_prefetchCheck( argumentCollection = arguments );
	}

	public void function requestEnd( event, rc, prc ) {
		_setXFrameOptionsHeader( argumentCollection = arguments );
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

		if ( isFeatureEnabled( "fullPageCaching" ) ) {
			event.cachePage( false );
		}

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

		var reloadPassword      = getSetting( name="reinitPassword",      defaultValue="true" );
		var devSettings         = getSetting( name="developerMode" ,      defaultValue=false );
		var disableMajorReloads = getSetting( name="disableMajorReloads", defaultValue=false );

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


			if ( !disableMajorReloads ) {
				if ( devSettings.dbSync or ( event.valueExists( "fwReinitDbSync" ) and Hash( rc.fwReinitDbSync ) eq reloadPassword ) ) {
					applicationReloadService.reloadPresideObjects();
					applicationReloadService.dbSync();
					anythingReloaded = true;
				} else if ( devSettings.reloadPresideObjects or ( event.valueExists( "fwReinitObjects" ) and Hash( rc.fwReinitObjects ) eq reloadPassword ) ) {
					applicationReloadService.reloadPresideObjects();
					anythingReloaded = true;
				}

				if ( devSettings.reloadPageTypes or ( event.valueExists( "fwReinitPageTypes" ) and Hash( rc.fwReinitPageTypes ) eq reloadPassword ) ) {
					applicationReloadService.reloadPageTypes();
					anythingReloaded = true;
				}
			}

			if ( devSettings.flushCaches or ( event.valueExists( "fwReinitCaches" ) and Hash( rc.fwReinitCaches ) eq reloadPassword ) ) {
				applicationReloadService.clearCaches();
				anythingReloaded = true;
			}

			if ( devSettings.reloadWidgets or ( event.valueExists( "fwReinitWidgets" ) and Hash( rc.fwReinitWidgets ) eq reloadPassword ) ) {
				applicationReloadService.reloadWidgets();
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
			if ( isFeatureEnabled( "websiteUsers" ) ) {
				websiteLoginService.recordVisit();
			}
			if ( isFeatureEnabled( "admin" ) ) {
				adminLoginService.recordVisit();
			}
		}
	}

	private void function _setLocale( event, rc, prc ) {
		SetLocale( getModel( "i18n" ).getFwLocale() );
	}

	private void function _prefetchCheck( event, rc, prc ) {
		if ( event.isActionRequest() && event.isPrefetchRequest() ) {
			content reset=true;
			header statuscode="400" statustext="Not allowed";
			abort;
		}
	}

	private void function _performDbMigrations() {
		coreDatabaseMigrationService.migrate();
		appDatabaseMigrationService.doMigrations();

		if ( isFeatureEnabled( "adhocTasks" ) ) {
			createTask(
				  event             = "general._performAsyncDbMigrations"
				, runIn             = CreateTimespan( 0, 0, 1, 0 ) // one minute, at least
				, discardOnComplete = true
			);
		}
	}

	private void function _performAsyncDbMigrations() {
		appDatabaseMigrationService.doMigrations( async=true );
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

		if ( isFeatureEnabled( "dataExport" ) ) {
			dataExportTemplateService.setupTemplatesEnum();
		}
		if ( isFeatureEnabled( "admin" ) ) {
			systemAlertsService.setupSystemAlerts();
		}
		if ( isFeatureEnabled( "presideForms" ) ) {
			formsService.formExists( "hack-to-ensure-service-initialised" );
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

		if ( isFeatureEnabled( "systemAlertsHeartBeat" ) ) {
			presideSystemAlertsHeartBeat.start();
		}

		if ( isFeatureEnabled( "presideSessionManagement" ) ) {
			presideSessionReapHeartbeat.start();
		}

		if ( isFeatureEnabled( "assetQueueHeartBeat" ) ) {
			for( var i=1; i<=assetQueueConcurrency; i++ ) {
				getModel( "AssetQueueHeartBeat#i#" ).start();
			}
		}

		if ( isFeatureEnabled( "scheduledExportHeartBeat" ) ) {
			scheduledExportHeartBeat.start();
		}

		if ( isFeatureEnabled( "segmentationFiltersHeartbeat" ) ) {
			segmentationFiltersHeartbeat.start();
		}

		cacheboxReapHeartBeat.start();
	}

	private void function _setupCatchAllAdminUserGroup() {
		if ( isFeatureEnabled( "admin" ) ) {
			permissionService.setupCatchAllGroup();
		}
	}

	private void function _setupValidators() {
		if ( IsArray( coreValidationProviders ) ) {
			for ( var providerName in coreValidationProviders ) {
				if ( getController().getWirebox().containsInstance( providerName ) ) {
					validationEngine.newProvider( getModel( providerName ) );
				}
			}
		}
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

	private void function _setXFrameOptionsHeader( event, rc, prc ) {
		var xframeOptions = prc.xframeoptions ?: "DENY";
		if ( xframeOptions != "ALLOW" ) {
			event.setHTTPHeader( name="X-Frame-Options", value=UCase( xframeOptions ), overwrite=true );
		}
	}

	private void function _runSystemAlertChecks() {
		if ( isFeatureEnabled( "admin" ) ) {
			systemAlertsService.runStartupChecks();
		}
	}

	private void function _setupEmailTemplating() {
		if ( isFeatureEnabled( "emailCenter" ) ) {
			emailTemplateService.ensureSystemTemplatesHaveDbEntries();
			systemEmailTemplateService.applicationStart();
		}
	}

	private void function _writeIgnoreFile() {
		ignoreFileService.write();
	}
}