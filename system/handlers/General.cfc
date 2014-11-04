component output=false {

	property name="presideObjectService"      inject="presideObjectService";
	property name="validationEngine"          inject="validationEngine";
	property name="presideFieldRuleGenerator" inject="presideFieldRuleGenerator";
	property name="formsService"              inject="formsService";
	property name="applicationReloadService"  inject="applicationReloadService";

	public void function applicationStart( event, rc, prc ) output=false {
		_autoRegisterPresideObjectValidators();
		prc._presideReloaded = true;
		announceInterception( "onApplicationStart" );
	}

	public void function requestStart( event, rc, prc ) output=false {
		_reloadChecks( argumentCollection = arguments );
	}

	public void function notFound( event, rc, prc ) output=false {
		var notFoundViewlet = getSetting( name="notFoundViewlet", defaultValue="errors.notFound" );
		var notFoundLayout  = getSetting( name="notFoundLayout" , defaultValue="Main" );

		event.setLayout( notFoundLayout );
		event.setView( view="/core/simpleBodyRenderer" );

		rc.body = renderViewlet( event=notFoundViewlet );
	}

	public void function accessDenied( event, rc, prc ) output=false {
		var accessDeniedViewlet = getSetting( name="accessDeniedViewlet", defaultValue="errors.accessDenied" );
		var accessDeniedLayout  = getSetting( name="accessDeniedLayout" , defaultValue="Main" );

		event.setLayout( accessDeniedLayout );
		event.setView( view="/core/simpleBodyRenderer" );

		rc.body = renderViewlet( event=accessDeniedViewlet, args=args );
	}

// private helpers
	private void function _autoRegisterPresideObjectValidators() output=false {
		var objects = presideObjectService.listObjects();
		var objName = "";
		var obj     = "";
		var ruleset = "";

		validationEngine.newProvider( getModel( "presideObjectValidators" ) );

		for( objName in objects ) {
			obj = presideObjectService.getObject( objName );
			if ( not IsSimpleValue( obj ) ) {
				validationEngine.newProvider( obj );

				ruleset = validationEngine.newRuleset( name="PresideObject.#objName#" );
				ruleset.addRules(
					rules = presideFieldRuleGenerator.generateRulesFromPresideObject( obj )
				);
			}
		}
	}

	private void function _reloadChecks( event, rc, prc ) output=false {
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
			} elseif ( devSettings.reloadPresideObjects or ( event.valueExists( "fwReinitObjects" ) and Hash( rc.fwReinitObjects ) eq reloadPassword ) ) {
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

			if ( event.valueExists( "fwReinitStatic" ) and Hash( rc.fwReinitStatic ) eq reloadPassword ) {
				applicationReloadService.reloadStatic();
				anythingReloaded = true;
			}
		}

		if ( anythingReloaded ) {
			_autoRegisterPresideObjectValidators();
		}
	}

	private boolean function _requestIsExcludedFromReload( event, rc, prc ) output=false {
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
}