<!---
	The helpers in this library should all be simple proxies to functionality declared elsewhere.
	The purpose is to provide straight forward access to such functionality without the need
	for calling code to have have to get the right plugin/service/etc.

	e.g.

	#renderViewlet( ... )# instead of #getController().renderviewlet( .... )#
--->

<!--- system settings --->
	<cffunction name="getSystemSetting" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "systemConfigurationService" ).getSetting( argumentCollection = arguments ) />
	</cffunction>

<!--- preside objects --->
	<cffunction name="getPresideObject" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "PresideObjectService" ).getObject( argumentCollection = arguments ) />
	</cffunction>

<!--- rendering --->
	<cffunction name="renderView" access="public" returntype="any" output="false">
		<cfscript>
			if ( Len( Trim( arguments.presideObject ?: "" ) ) ) {
				return getController().getWireBox().getInstance( "presideObjectViewService" ).renderView(
					argumentCollection = arguments
				);
			}

			return getController().getPlugin( "Renderer" ).renderView( argumentCollection=arguments );
		</cfscript>
	</cffunction>

	<cffunction name="renderViewlet" access="public" returntype="any" output="false">
		<cfreturn getController().renderViewlet( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderContent" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "contentRendererService" ).render( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderEditableContent" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "contentRendererService" ).makeContentEditable( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderField" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "contentRendererService" ).renderField( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderLink" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="true" />
		<cfreturn getController().renderViewlet( event="renderers.link.default", args=arguments ) />
	</cffunction>

	<cffunction name="renderAsset" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "assetRendererService" ).renderAsset( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderNotification" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "notificationService" ).renderNotification( argumentCollection = arguments ) />
	</cffunction>



<!--- WIDGETS --->
	<cffunction name="renderWidget" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "widgetsService" ).renderWidget( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderWidgetConfigForm" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "widgetsService" ).renderWidgetConfigForm( argumentCollection = arguments ) />
	</cffunction>


<!--- FORMS --->
	<cffunction name="renderForm" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "formsService" ).renderForm( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="renderFormControl" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "formsService" ).renderFormControl( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="validateForm" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "formsService" ).validateForm( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="preProcessForm" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "formsService" ).preProcessForm( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="preProcessFormField" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "formsService" ).preProcessFormField( argumentCollection=arguments ) />
	</cffunction>

<!--- i18n --->
	<cffunction name="translateResource" access="public" returntype="any" output="false">
		<cfreturn getController().getPlugin( "i18n" ).translateResource( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="translateValidationMessages" access="public" returntype="struct" output="false">
		<cfargument name="validationResult" type="any" required="true" />

		<cfscript>
			var messages   = arguments.validationResult.getMessages();
			var translated = {};

			for( var field in messages ){
				translated[ field ] = translateResource(
					  uri          = messages[field].message ?: ""
					, defaultValue = messages[field].message ?: ""
					, data         = messages[field].params  ?: []
				);
			}

			return translated;
		</cfscript>
	</cffunction>

<!--- permissioning and users --->
	<cffunction name="hasCmsPermission" access="public" returntype="boolean" output="false">
		<cfreturn getController().getWireBox().getInstance( "permissionService" ).hasPermission( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="hasWebsitePermission" access="public" returntype="boolean" output="false">
		<cfreturn getController().getWireBox().getInstance( "websitePermissionService" ).hasPermission( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="isLoggedIn" access="public" returntype="boolean" output="false">
		<cfreturn getController().getWireBox().getInstance( "websiteLoginService" ).isLoggedIn( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="isAutoLoggedIn" access="public" returntype="boolean" output="false">
		<cfreturn getController().getWireBox().getInstance( "websiteLoginService" ).isAutoLoggedIn( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="getLoggedInUserId" access="public" returntype="string" output="false">
		<cfreturn getController().getWireBox().getInstance( "websiteLoginService" ).getLoggedInUserId( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="getLoggedInUserDetails" access="public" returntype="struct" output="false">
		<cfreturn getController().getWireBox().getInstance( "websiteLoginService" ).getLoggedInUserDetails( argumentCollection=arguments ) />
	</cffunction>

<!--- features --->
	<cffunction name="isFeatureEnabled" access="public" returntype="boolean" output="false">
		<cfreturn getController().getWireBox().getInstance( "featureService" ).isFeatureEnabled( argumentCollection=arguments ) />
	</cffunction>