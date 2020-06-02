<!---
	The helpers in this library should all be simple proxies to functionality declared elsewhere.
	The purpose is to provide straight forward access to such functionality without the need
	for calling code to have have to get the right plugin/service/etc.

	e.g.

	#renderViewlet( ... )# instead of #getController().renderviewlet( .... )#
--->

<!--- system settings --->
	<cffunction name="getSystemSetting" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "systemConfigurationService" ).getSetting( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="getSystemCategorySettings" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "systemConfigurationService" ).getCategorySettings( argumentCollection = arguments ) />
	</cffunction>

<!--- preside objects --->
	<cffunction name="getPresideObject" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "PresideObjectService" ).getObject( argumentCollection = arguments ) />
	</cffunction>

<!--- rendering --->
	<cffunction name="renderViewlet" access="public" returntype="any" output="false">
		<cfreturn getController().renderViewlet( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderContent" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "contentRendererService" ).render( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderEditableContent" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "contentRendererService" ).makeContentEditable( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderField" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "contentRendererService" ).renderField( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderLabel" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "contentRendererService" ).renderLabel( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderLink" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="true" />
		<cfreturn getController().renderViewlet( event="renderers.link.default", args=arguments ) />
	</cffunction>

	<cffunction name="getLinkUrl" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "linksService" ).getLinkUrl( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderAsset" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "assetRendererService" ).renderAsset( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderNotification" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "notificationService" ).renderNotification( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderAuditLog" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "AuditService" ).renderAuditLog( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderLogMessage" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "AuditService" ).renderLogMessage( argumentCollection = arguments ) />
	</cffunction>

<!--- WIDGETS --->
	<cffunction name="renderWidget" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "widgetsService" ).renderWidget( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderWidgetConfigForm" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "widgetsService" ).renderWidgetConfigForm( argumentCollection = arguments ) />
	</cffunction>


<!--- FORMS --->
	<cffunction name="renderForm" access="public" returntype="any" output="false">
		<cfscript>
			if ( !StructKeyExists( arguments, "validationJsJqueryRef" ) ) {
				var event = getController().getRequestContext();

				arguments.validationJsJqueryRef = event.isAdminRequest() ? "presideJQuery" : "jQuery";
			}

			return getSingleton( "formsService" ).renderForm( argumentCollection=arguments );
		</cfscript>
	</cffunction>

	<cffunction name="renderFormControl" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "formsService" ).renderFormControl( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="validateForm" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "formsService" ).validateForm( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="validateForms" access="public" returntype="any" output="false">
		<cfargument name="formData" type="struct" default="#getController().getRequestContext().getCollection()#" />
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
	</cffunction>

	<cffunction name="preProcessForm" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "formsService" ).preProcessForm( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="preProcessFormField" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "formsService" ).preProcessFormField( argumentCollection=arguments ) />
	</cffunction>

<!--- i18n --->
	<cffunction name="translateResource" access="public" returntype="any" output="false">
		<cfscript>
			var args     = arguments;
			var cacheKey = "translateResource" & SerializeJson( args );

			return simpleRequestCache( cacheKey, function(){
				return getSingleton( "i18n" ).translateResource( argumentCollection = args )
			} );
		</cfscript>
	</cffunction>

	<cffunction name="translateObjectName" access="public" returntype="any" output="false">
		<cfscript>
			var args     = arguments;
			var cacheKey = "translateObjectName" & SerializeJson( args );

			return simpleRequestCache( cacheKey, function(){
				return getSingleton( "i18n" ).translateObjectName( argumentCollection = args )
			} );
		</cfscript>
	</cffunction>

	<cffunction name="translatePropertyName" access="public" returntype="any" output="false">
		<cfscript>
			var args     = arguments;
			var cacheKey = "translatePropertyName" & SerializeJson( args );

			return simpleRequestCache( cacheKey, function(){
				return getSingleton( "i18n" ).translatePropertyName( argumentCollection = args )
			} );
		</cfscript>
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

	<cffunction name="translateObjectProperty" access="public" returntype="any" output="false">
		<cfargument name="objectName"   type="string" required="true" />
		<cfargument name="propertyname" type="string" required="true" />
		<cfargument name="defaultValue" type="string" required="false" default="#arguments.propertyName#" />

		<cfscript>
			var baseUri      = getSingleton( "presideObjectService" ).getResourceBundleUriRoot( arguments.objectName );
			var fullUri      = baseUri & "field.#propertyName#.title";
			var defaultValue = translateResource( uri="cms:preside-objects.default.field.#propertyName#.title", defaultValue=arguments.defaultValue );

			return translateResource( uri=fullUri, defaultValue=defaultValue );
		</cfscript>
	</cffunction>

	<cffunction name="translateObjectName" access="public" returntype="any" output="false">
		<cfargument name="objectName"   type="string" required="true" />

		<cfscript>
			var poService    = getSingleton( "presideObjectService" );
			var baseUri      = poService.getResourceBundleUriRoot( arguments.objectName );
			var isPageType   = poService.isPageType( arguments.objectName );
			var fullUri      = baseUri & ( isPageType ? "name" : "title.singular" );

			return translateResource( uri=fullUri, defaultValue=arguments.objectName );
		</cfscript>
	</cffunction>

<!--- permissioning and users --->
	<cffunction name="hasCmsPermission" access="public" returntype="boolean" output="false">
		<cfreturn getSingleton( "permissionService" ).hasPermission( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="hasCmsPermissions" access="public" returntype="struct" output="false">
		<cfreturn getSingleton( "permissionService" ).hasPermissions( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="hasWebsitePermission" access="public" returntype="boolean" output="false">
		<cfreturn getSingleton( "websitePermissionService" ).hasPermission( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="isLoggedIn" access="public" returntype="boolean" output="false">
		<cfreturn getSingleton( "websiteLoginService" ).isLoggedIn( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="isAutoLoggedIn" access="public" returntype="boolean" output="false">
		<cfreturn getSingleton( "websiteLoginService" ).isAutoLoggedIn( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="getLoggedInUserId" access="public" returntype="string" output="false">
		<cfreturn getSingleton( "websiteLoginService" ).getLoggedInUserId( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="getLoggedInUserDetails" access="public" returntype="struct" output="false">
		<cfreturn getSingleton( "websiteLoginService" ).getLoggedInUserDetails( argumentCollection=arguments ) />
	</cffunction>

<!--- features --->
	<cffunction name="isFeatureEnabled" access="public" returntype="boolean" output="false">
		<cfargument name="feature"      type="string" required="true" />
		<cfargument name="siteTemplate" type="string" required="false" default="#getSingleton( "siteService" ).getActiveSiteTemplate()#" />

		<cfreturn getSingleton( "featureService" ).isFeatureEnabled( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="isFeatureDefined" access="public" returntype="boolean" output="false">
		<cfreturn getSingleton( "featureService" ).isFeatureDefined( argumentCollection=arguments ) />
	</cffunction>

<!--- errors --->
	<cffunction name="logError" access="public" returntype="void" output="false">
		<cfreturn getController().getWireBox().getInstance( "errorLogService" ).raiseError( argumentCollection=arguments ) />
	</cffunction>

<!--- tasks --->
	<cffunction name="createTask" access="public" returntype="any" output="false">
		<cfreturn getSingleton( "adHocTaskManagerService" ).createTask( argumentCollection=arguments ) />
	</cffunction>

<!--- utils --->
	<cffunction name="slugify" access="public" returntype="string" output="false">
		<cfreturn getSingleton( "PresideObjectService" ).slugify( argumentCollection=arguments )>
	</cffunction>

<!--- datamanager --->
	<cffunction name="objectDataTable" access="public" returntype="string" output="false">
		<cfargument name="objectName" type="string" required="true" />
		<cfargument name="args"       type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			arguments.args.objectName = arguments.objectName;

			return getSingleton( "dataManagerCustomizationService" ).runCustomization(
				  objectName     = arguments.objectName
				, args           = arguments.args
				, action         = "listingViewlet"
				, defaultHandler = "admin.DataManager._objectListingViewlet"
			);
		</cfscript>
	</cffunction>

<!--- healthchecks --->
	<cffunction name="isUp" access="public" returntype="any" output="false">
		<cfargument name="serviceId" type="string" required="true" />

		<cfreturn getSingleton( "healthcheckService" ).isUp( argumentCollection=arguments ) />
	</cffunction>

	<cffunction name="isDown" access="public" returntype="any" output="false">
		<cfargument name="serviceId" type="string" required="true" />

		<cfreturn !getSingleton( "healthcheckService" ).isUp( argumentCollection=arguments ) />
	</cffunction>

<!--- helpers --->
	<cffunction name="simpleRequestCache" access="public" returntype="any" output="false">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="generator" type="any" required="true" />

		<cfscript>
			request._simpleRequestCache = request._simpleRequestCache ?: {};

			if ( !StructKeyExists( request._simpleRequestCache, arguments.key ) ) {
				request._simpleRequestCache[ arguments.key ] = arguments.generator();
			}

			return request._simpleRequestCache[ arguments.key ];
		</cfscript>
	</cffunction>
	<cffunction name="getSingleton" access="public" returntype="any" output="false">
		<cfargument name="objectName" type="string" required="true" />

		<cfscript>
			var args = arguments;
			return simpleRequestCache( "getSingleton" & args.objectName, function(){
				return getController().getWireBox().getInstance( args.objectName );
			} );
		</cfscript>
	</cffunction>