<cfcomponent output="false">

	<cfproperty name="presideObjectService"      inject="presideObjectService"      />
	<cfproperty name="validationEngine"          inject="validationEngine"          />
	<cfproperty name="presideFieldRuleGenerator" inject="presideFieldRuleGenerator" />
	<cfproperty name="formsService"              inject="formsService"              />
	<cfproperty name="applicationReloadService"  inject="applicationReloadService"  />

	<cffunction name="applicationStart" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			_autoRegisterPresideObjectValidators();

			prc._presideReloaded = true;
		</cfscript>
	</cffunction>

	<cffunction name="requestStart" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			_reloadChecks( argumentCollection = arguments );
		</cfscript>
	</cffunction>

	<cffunction name="notFound" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var notFoundViewlet = getSetting( name="notFoundViewlet", defaultValue="errors.notFound" );
			var notFoundLayout  = getSetting( name="notFoundLayout" , defaultValue="Main" );

			event.setLayout( notFoundLayout );
			event.setView( view="/core/simpleBodyRenderer" );

			rc.body = renderViewlet( event=notFoundViewlet );

		</cfscript>
	</cffunction>

	<cffunction name="accessDenied" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />
		<cfargument name="args"  type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			var accessDeniedViewlet = getSetting( name="accessDeniedViewlet", defaultValue="errors.accessDenied" );
			var accessDeniedLayout  = getSetting( name="accessDeniedLayout" , defaultValue="Main" );

			event.setLayout( accessDeniedLayout );
			event.setView( view="/core/simpleBodyRenderer" );

			rc.body = renderViewlet( event=accessDeniedViewlet, args=args );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_autoRegisterPresideObjectValidators" access="private" returntype="void" output="false">
		<cfscript>
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
		</cfscript>
	</cffunction>

	<cffunction name="_reloadChecks" access="private" returntype="void" output="false">
		<cfargument name="event" type="any" required="true" />
		<cfargument name="rc"    type="any" required="true" />
		<cfargument name="prc"   type="any" required="true" />

		<cfscript>
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
		</cfscript>
	</cffunction>

	<cffunction name="_requestIsExcludedFromReload" access="private" returntype="boolean" output="false">
		<cfargument name="event" type="any" required="true" />
		<cfargument name="rc"    type="any" required="true" />
		<cfargument name="prc"   type="any" required="true" />

		<cfscript>
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
		</cfscript>
	</cffunction>
</cfcomponent>