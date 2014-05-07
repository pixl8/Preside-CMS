<cfcomponent output="false">

	<cfproperty name="presideObjectService"      inject="presideObjectService"      />
	<cfproperty name="validationEngine"          inject="validationEngine"          />
	<cfproperty name="presideFieldRuleGenerator" inject="presideFieldRuleGenerator" />
	<cfproperty name="formsService"              inject="formsService"              />
	<cfproperty name="pageTemplatesService"      inject="pageTemplatesService"      />
	<cfproperty name="applicationReloadService"  inject="applicationReloadService"  />

	<cffunction name="applicationStart" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			if ( _presideEventsSystemIsEnabled() ) {
				_registerPresideListeners();
			}

			applicationReloadService.dbSync();
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

<!--- private helpers --->
	<cffunction name="_registerPresideListeners" access="private" returntype="void" output="false">
		<cfscript>
			var listeners = getSetting( name="event_listeners", defaultValue=ArrayNew(1) );
			var i         = 0;

// TODO, replace this bad boy listener system with coldbox events			application.obj.presideevents.setBeanFactory( application.beanFactory );
/*
			_registerPresideListener({
				  events             = "on_after_flush"
				, eventSources       = "sitetree"
				, listenerBean       = "siteTreeService"
				, listenerMethod     = "clearCache"
				, propagateToCluster = true
			});

			for( i=1; i lte ArrayLen( listeners ); i++ ) {
				_registerPresideListener( listeners[i] );

			}
*/
		</cfscript>
	</cffunction>

	<cffunction name="_registerPresideListener" access="private" returntype="void" output="false">
		<cfargument name="listenerConfig" type="struct" required="true" />

		<cfparam name="arguments.listenerConfig.events"             default="" />
		<cfparam name="arguments.listenerConfig.eventSources"       default="" />
		<cfparam name="arguments.listenerConfig.listenerBean"       default="" />
		<cfparam name="arguments.listenerConfig.listenerMethod"     default="" />
		<cfparam name="arguments.listenerConfig.propagateToCluster" default="true" />

		<cfscript>
			var sources = ListToArray( Trim( arguments.listenerConfig.eventSources ) );
			var events  = ListToArray( Trim( arguments.listenerConfig.events ) );
			var i       = 0;
			var n       = 0;
			var validListener = ( ArrayLen( sources ) and ArrayLen( events ) and Len( Trim( arguments.listenerConfig.listenerBean ) ) );

			if ( not validListener ) {
				throw( type="preside.invalidListenerConfig", message="Listener configurations require a non-empty 'events', 'eventSources' and 'listenerBean' attribute." );
			}

			if ( not beanExists( arguments.listenerConfig.listenerBean ) ) {
				throw( type="preside.invalidListenerConfig", message="A listener was configured to use the coldspring bean, '#arguments.listenerConfig.listenerBean#'. However, no bean with that id exists." );
			}

			for( i=1; i lte ArrayLen( events ); i++ ){
				for( n=1; n lte ArrayLen( sources ); n++ ){
					application.obj.presideevents.addListener(
						  event              = events[i]
						, eventSource        = sources[n]
						, listenerId         = Hash( events[i] & sources[n] & arguments.listenerConfig.listenerBean & arguments.listenerConfig.listenerMethod )
						, listenerObject     = arguments.listenerConfig.listenerBean
						, listenerMethod     = Len( Trim( arguments.listenerConfig.listenerMethod ) ) ? arguments.listenerConfig.listenerMethod : events[i]
						, useBeanFactory     = true
						, propagateToCluster = arguments.listenerConfig.propagateToCluster
					);
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_presideEventsSystemIsEnabled" access="private" returntype="boolean" output="false">
		<cfreturn IsDefined( 'application.obj.presideevents' ) /><!--- refactor some day please! --->
	</cffunction>

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
					, reloadPageTemplates  = devSettings
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
					, reloadPageTemplates  = IsBoolean( devSettings.reloadPageTemplates  ?: "" ) and devSettings.reloadPageTemplates
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

				if ( devSettings.reloadPageTemplates or ( event.valueExists( "fwReinitTemplates" ) and Hash( rc.fwReinitTemplates ) eq reloadPassword ) ) {
					applicationReloadService.reloadPageTemplates();
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
				if ( _presideEventsSystemIsEnabled() ) {
					_registerPresideListeners();
				}
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

			if ( ReFindNoCase( "^(assetDownload|ajaxproxy)", event.getCurrentHandler() ) ) {
				return true;
			}

			return false;
		</cfscript>
	</cffunction>
</cfcomponent>