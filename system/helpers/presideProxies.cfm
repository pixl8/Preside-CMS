<!---
	The helpers in this library should all be simple proxies to functionality declared elsewhere.
	The purpose is to provide straight forward access to such functionality without the need
	for calling code to have have to get the right plugin/service/etc.

	e.g.

	#renderViewlet( ... )# instead of #getController().renderviewlet( .... )#
--->

<!--- preside objects --->
	<cffunction name="getPresideObject" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "PresideObjectService" ).getObject( argumentCollection = arguments ) />
	</cffunction>

<!--- rendering --->
	<cffunction name="renderViewlet" access="public" returntype="any" output="false">
		<cfreturn getController().renderViewlet( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderContent" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "contentRenderer" ).render( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderField" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "contentRenderer" ).renderField( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderPresideObjectView" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "presideObjectViewService" ).renderView( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderAsset" access="public" returntype="any" output="false">
		<cfreturn getController().getWireBox().getInstance( "assetRendererService" ).renderAsset( argumentCollection = arguments ) />
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

<!--- permissioning --->
	<cffunction name="hasPermission" access="public" returntype="boolean" output="false">
		<cfreturn getController().getWireBox().getInstance( "permissionService" ).hasPermission( argumentCollection=arguments ) />
	</cffunction>