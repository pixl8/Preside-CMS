<!---
	The helpers in this library should all be simple proxies to functionality declared elsewhere.
	The purpose is to provide straight forward access to such functionality without the need
	for calling code to have to get the right plugin/service/etc.

	e.g.

	#renderViewlet( ... )# instead of #getController().renderviewlet( .... )#
--->

<!--- system settings --->
	<cffunction name="getSystemSetting" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "systemConfigurationService" ).getSetting( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="getSystemCategorySettings" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "systemConfigurationService" ).getCategorySettings( argumentCollection = arguments ) />
	</cfsilent></cffunction>

<!--- preside objects --->
	<cffunction name="getPresideObject" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "PresideObjectService" ).getObject( argumentCollection = arguments ) />
	</cfsilent></cffunction>

<!--- rendering --->
	<cffunction name="renderViewlet" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getController().renderViewlet( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderContent" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "contentRendererService" ).render( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderEditableContent" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "contentRendererService" ).makeContentEditable( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderField" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "contentRendererService" ).renderField( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderLabel" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "contentRendererService" ).renderLabel( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderLink" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="true" /><cfsilent>
		<cfreturn getController().renderViewlet( event="renderers.link.default", args=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="getLinkUrl" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "linksService" ).getLinkUrl( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderAsset" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "assetRendererService" ).renderAsset( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="getAssetDimensions" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "assetManagerService" ).getAssetDimensions( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderNotification" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "notificationService" ).renderNotification( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderAuditLog" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "AuditService" ).renderAuditLog( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderLogMessage" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "AuditService" ).renderLogMessage( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderEnum" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "ContentRendererService" ).renderEnum( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- WIDGETS --->
	<cffunction name="renderWidget" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "widgetsService" ).renderWidget( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="renderWidgetConfigForm" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "widgetsService" ).renderWidgetConfigForm( argumentCollection = arguments ) />
	</cfsilent></cffunction>


<!--- FORMS --->
	<cffunction name="renderForm" access="public" returntype="any" output="false"><cfsilent>
		<cfscript>
			if ( !StructKeyExists( arguments, "validationJsJqueryRef" ) ) {
				var event = getController().getRequestContext();

				arguments.validationJsJqueryRef = event.isAdminRequest() ? "presideJQuery" : "jQuery";
			}

			return getSingleton( "formsService" ).renderForm( argumentCollection=arguments );
		</cfscript>
	</cfsilent></cffunction>

	<cffunction name="renderFormControl" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "formsService" ).renderFormControl( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="validateForm" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "formsService" ).validateForm( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="validateForms" access="public" returntype="any" output="false">
		<cfargument name="formData" type="struct" default="#getController().getRequestContext().getCollection()#" /><cfsilent>
		<cfscript>
			var formsService     = getSingleton( "formsService" );
			var validationResult = getSingleton( "validationEngine" ).newValidationResult();
			var event            = getController().getRequestContext();
			var formNames        = event.getSubmittedPresideForms();

			for( var formName in formNames ) {

				validationResult = formsService.validateForm(
					  argumentCollection = arguments
					, formName           = formName
					, formData           = arguments.formData
					, validationResult   = validationResult
				);
			}

			return validationResult;
		</cfscript>
	</cfsilent></cffunction>

	<cffunction name="preProcessForm" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "formsService" ).preProcessForm( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="preProcessFormField" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "formsService" ).preProcessFormField( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- i18n --->
	<cffunction name="getResourceBundleUriRoot" access="public" returntype="any" output="false">
		<cfargument name="objectName" type="string" required="true" /><cfsilent>

		<cfscript>
			return getSingleton( "presideObjectService" ).getResourceBundleUriRoot( arguments.objectName );
		</cfscript>
	</cfsilent></cffunction>

	<cffunction name="translateResource" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "i18n" ).translateResource( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="translateObjectName" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "i18n" ).translateObjectName( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="translatePropertyName" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "i18n" ).translatePropertyName( argumentCollection = arguments ) />
	</cfsilent></cffunction>

	<cffunction name="translateValidationMessages" access="public" returntype="struct" output="false">
		<cfargument name="validationResult" type="any" required="true" /><cfsilent>

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
	</cfsilent></cffunction>

	<cffunction name="translateObjectProperty" access="public" returntype="any" output="false">
		<cfargument name="objectName"   type="string" required="true" />
		<cfargument name="propertyname" type="string" required="true" />
		<cfargument name="defaultValue" type="string" required="false" default="#arguments.propertyName#" /><cfsilent>

		<cfscript>
			var baseUri      = getSingleton( "presideObjectService" ).getResourceBundleUriRoot( arguments.objectName );
			var fullUri      = baseUri & "field.#propertyName#.title";
			var defaultValue = translateResource( uri="cms:preside-objects.default.field.#propertyName#.title", defaultValue=arguments.defaultValue );

			return translateResource( uri=fullUri, defaultValue=defaultValue );
		</cfscript>
	</cfsilent></cffunction>

<!--- permissioning and users --->
	<cffunction name="hasCmsPermission" access="public" returntype="boolean" output="false"><cfsilent>
		<cfreturn getSingleton( "permissionService" ).hasPermission( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="hasCmsPermissions" access="public" returntype="struct" output="false"><cfsilent>
		<cfreturn getSingleton( "permissionService" ).hasPermissions( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="hasAnyCmsPermissions" access="public" returntype="boolean" output="false"><cfsilent>
		<cfreturn getSingleton( "permissionService" ).hasAnyPermissions( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="hasWebsitePermission" access="public" returntype="boolean" output="false"><cfsilent>
		<cfreturn isFeatureEnabled( "websiteUsers" ) && getSingleton( "websitePermissionService" ).hasPermission( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="isLoggedIn" access="public" returntype="boolean" output="false"><cfsilent>
		<cfreturn isFeatureEnabled( "websiteUsers" ) && getSingleton( "websiteLoginService" ).isLoggedIn( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="isAutoLoggedIn" access="public" returntype="boolean" output="false"><cfsilent>
		<cfreturn isFeatureEnabled( "websiteUsers" ) && getSingleton( "websiteLoginService" ).isAutoLoggedIn( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="getLoggedInUserId" access="public" returntype="string" output="false"><cfsilent>
		<cfif !isFeatureEnabled( "websiteUsers" )>
			<cfreturn "" />
		</cfif>
		<cfreturn getSingleton( "websiteLoginService" ).getLoggedInUserId( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="getLoggedInUserDetails" access="public" returntype="struct" output="false"><cfsilent>
		<cfif !isFeatureEnabled( "websiteUsers" )>
			<cfreturn {} />
		</cfif>
		<cfreturn getSingleton( "websiteLoginService" ).getLoggedInUserDetails( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="reloadLoggedInUserDetails" access="public" returntype="void" output="false"><cfsilent>
		<cfif !isFeatureEnabled( "websiteUsers" )>
			<cfreturn />
		</cfif>
		<cfreturn getSingleton( "websiteLoginService" ).reloadLoggedInUserDetails( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- features --->
	<cffunction name="isFeatureEnabled" access="public" returntype="boolean" output="false">
		<cfargument name="feature"      type="string" required="true" />
		<cfargument name="siteTemplate" type="string" required="false" default="_active" /><cfsilent>

		<cfreturn getSingleton( "featureService" ).isFeatureEnabled( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="isFeatureDefined" access="public" returntype="boolean" output="false"><cfsilent>
		<cfreturn getSingleton( "featureService" ).isFeatureDefined( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="isExtensionInstalled" access="public" returntype="boolean" output="false">
		<cfargument name="extensionId" type="string" required="true" /><cfsilent>

		<cfreturn getSingleton( "extensionManagerService" ).extensionExists( argumentCollection=arguments ) />
	</cfsilent></cffunction>


<!--- errors --->
	<cffunction name="logError" access="public" returntype="void" output="false"><cfsilent>
		<cfreturn getController().getWireBox().getInstance( "errorLogService" ).raiseError( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- system alerts --->
	<cffunction name="runSystemAlertCheck" access="public" returntype="any" output="false">
		<cfargument name="type"      type="string"  required="true" />
		<cfargument name="reference" type="string"  default="" />
		<cfargument name="async"     type="boolean" default="true" />
		<cfargument name="trigger"   type="string"  default="code" /><cfsilent>

		<cfreturn getController().getWireBox().getInstance( "systemAlertsService" ).runCheck( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- tasks --->
	<cffunction name="createTask" access="public" returntype="any" output="false"><cfsilent>
		<cfreturn getSingleton( "adHocTaskManagerService" ).createTask( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- utils --->
	<cffunction name="slugify" access="public" returntype="string" output="false"><cfsilent>
		<cfreturn getSingleton( "PresideObjectService" ).slugify( argumentCollection=arguments )>
	</cfsilent></cffunction>

	<cffunction name="isFlaggingEnabled" access="public" returntype="boolean" output="false">
		<cfargument name="objectName" type="string" required="true" /><cfsilent>

		<cfreturn getSingleton( "PresideObjectService" ).isFlaggingEnabled( objectName=arguments.objectName )>
	</cfsilent></cffunction>

<!--- datamanager --->
	<cffunction name="objectDataTable" access="public" returntype="string" output="false">
		<cfargument name="objectName" type="string" required="true" />
		<cfargument name="args"       type="struct" required="false" default="#StructNew()#" /><cfsilent>

		<cfscript>
			arguments.args.objectName = arguments.objectName;

			return getSingleton( "dataManagerCustomizationService" ).runCustomization(
				  objectName     = arguments.objectName
				, args           = arguments.args
				, action         = "listingViewlet"
				, defaultHandler = "admin.DataManager._objectListingViewlet"
			);
		</cfscript>
	</cfsilent></cffunction>

	<cffunction name="objectTreeView" access="public" returntype="string" output="false">
		<cfargument name="objectName" type="string" required="true" />
		<cfargument name="args"       type="struct" required="false" default="#StructNew()#" /><cfsilent>

		<cfscript>
			arguments.args.objectName = arguments.objectName;
			arguments.args.treeOnly   = true;

			return getSingleton( "dataManagerCustomizationService" ).runCustomization(
				  objectName     = arguments.objectName
				, args           = arguments.args
				, action         = "listingViewlet"
				, defaultHandler = "admin.DataManager._objectListingViewlet"
			);
		</cfscript>
	</cfsilent></cffunction>

<!--- healthchecks --->
	<cffunction name="isUp" access="public" returntype="any" output="false">
		<cfargument name="serviceId" type="string" required="true" /><cfsilent>

		<cfreturn getSingleton( "healthcheckService" ).isUp( argumentCollection=arguments ) />
	</cfsilent></cffunction>

	<cffunction name="isDown" access="public" returntype="any" output="false">
		<cfargument name="serviceId" type="string" required="true" /><cfsilent>

		<cfreturn !getSingleton( "healthcheckService" ).isUp( argumentCollection=arguments ) />
	</cfsilent></cffunction>

<!--- helpers --->
	<cffunction name="simpleRequestCache" access="public" returntype="any" output="false">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="generator" type="any" required="true" /><cfsilent>

		<cfscript>
			request._simpleRequestCache = request._simpleRequestCache ?: {};

			if ( !StructKeyExists( request._simpleRequestCache, arguments.key ) ) {
				request._simpleRequestCache[ arguments.key ] = arguments.generator();
			}

			return request._simpleRequestCache[ arguments.key ];
		</cfscript>
	</cfsilent></cffunction>
	<cffunction name="getSingleton" access="public" returntype="any" output="false">
		<cfargument name="objectName" type="string" required="true" /><cfsilent>

		<cfscript>
			var args = arguments;
			return simpleRequestCache( "getSingleton" & args.objectName, function(){
				return getController().getWireBox().getInstance( args.objectName );
			} );
		</cfscript>
	</cfsilent></cffunction>