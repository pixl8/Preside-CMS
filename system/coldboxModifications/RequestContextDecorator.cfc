<!---
	Helper methods and standard event method overrides that are specific to Preside
	live here.
--->

<cfcomponent extends="coldbox.system.web.context.RequestContextDecorator" output="false">

<!--- URL related --->
	<cffunction name="setSite" access="public" returntype="void" output="false">
		<cfargument name="site" type="struct" required="true" />

		<cfscript>
			getRequestContext().setValue(
				  name    = "_site"
				, value   =  arguments.site
				, private =  true
			);
		</cfscript>
	</cffunction>

	<cffunction name="getSite" access="public" returntype="struct" output="false">
		<cfscript>
			var site = getRequestContext().getValue( name="_site", private=true, defaultValue={} );

			if ( IsStruct( site ) ) {
				return site;
			}

			return {};
		</cfscript>
	</cffunction>

	<cffunction name="getSiteUrl" access="public" returntype="string" output="false">
		<cfargument name="includePath" type="boolean" required="false" default="true" />
		<cfscript>
			var site    = getSite;
			var siteUrl = ( site.protocol ?: "http" ) & "://" & ( site.domain ?: cgi.server_name );

			if ( arguments.includePath ) {
				siteUrl &= site.path ?: "/";
			}

			return siteUrl;
		</cfscript>
	</cffunction>

	<cffunction name="getSiteId" access="public" returntype="string" output="false">
		<cfscript>
			var site = getSite();

			return site.id ?: "";
		</cfscript>
	</cffunction>

	<cffunction name="buildLink" access="public" returntype="string" output="false">
		<cfscript>
			var prc = getRequestContext().getCollection( private=true );

			announceInterception(
				  state         = "onBuildLink"
				, interceptData = arguments
			);

			var link = prc._builtLink ?: "";
			StructDelete( prc, "_builtLink" );

			if ( not Len( Trim( link ) ) and Len( Trim( arguments.linkTo ?: "" ) ) ) {
				link = getRequestContext().buildLink( argumentCollection = arguments );
			}

			link = Replace( link, "//", "/", "all" );
			link = ReReplace( link, "^(https?):/", "\1://" );

			return link;
		</cfscript>
	</cffunction>

	<cffunction name="getProtocol" access="public" returntype="string" output="false">
		<cfreturn cgi.server_protocol contains "https" ? "https" : "http" />
	</cffunction>

	<cffunction name="getServerName" access="public" returntype="string" output="false">
		<cfreturn cgi.server_name />
	</cffunction>

	<cffunction name="getBaseUrl" access="public" returntype="string" output="false">
		<cfreturn getProtocol() & "://" & getServerName() />
	</cffunction>

	<cffunction name="getCollectionWithoutSystemVars" access="public" returntype="struct" output="false">
		<cfscript>
			var collection = Duplicate( getRequestContext().getCollection() );

			StructDelete( collection, "csrfToken"   );
			StructDelete( collection, "action"      );
			StructDelete( collection, "event"       );
			StructDelete( collection, "handler"     );
			StructDelete( collection, "module"      );
			StructDelete( collection, "fieldnames"  );

			return collection;
		</cfscript>
	</cffunction>

	<cffunction name="getCollectionForForm" access="public" returntype="struct" output="false">
		<cfargument name="formName" type="string" required="true" />

		<cfscript>
			var formFields = getModel( "formsService" ).listFields( arguments.formName );
			var collection = {};
			var rc         = getRequestContext().getCollection();

			for( var field in formFields ){
				collection[ field ] = ( rc[ field ] ?: "" );
			}

			return collection;
		</cfscript>
	</cffunction>



<!--- Admin specific --->
	<cffunction name="buildAdminLink" access="public" returntype="string" output="false">
		<cfargument name="linkTo"      type="string" required="false" default="" />
		<cfargument name="queryString" type="string" required="false" default="" />

		<cfscript>
			arguments.linkTo = ListAppend( "admin", arguments.linkTo, "." );

			if ( isActionRequest( arguments.linkTo ) ) {
				arguments.queryString = ListAppend( arguments.queryString, "csrfToken=" & this.getCsrfToken(), "&" );
			}

			return buildLink( argumentCollection = arguments );
		</cfscript>
	</cffunction>

	<cffunction name="getAdminPath" access="public" returntype="string" output="false">
		<cfscript>
			var overridenSetting = getModel( "systemConfigurationService" ).getSetting( "general", "admin_url" );
			var path             = Len( Trim( overridenSetting ) ) ? overridenSetting : getController().getSetting( "preside_admin_path" );



			return Len( Trim( path ) ) ? "/#path#/" : "/";
		</cfscript>
	</cffunction>

	<cffunction name="getCurrentUrl" access="public" returntype="string" output="false">
		<cfargument name="includeQueryString" type="boolean" required="false" default="true" />

		<cfscript>
			var currentUrl  = request[ "preside.path_info"    ] ?: "";
			var qs          = request[ "preside.query_string" ] ?: "";
			var includeQs   = arguments.includeQueryString && Len( Trim( qs ) );

			return includeQs ? currentUrl & "?" & qs : currentUrl;
		</cfscript>
	</cffunction>

	<cffunction name="isAdminUser" access="public" returntype="boolean" output="false">
		<cfscript>
			var loginSvc = getModel( "loginService" );

			return loginSvc.isLoggedIn();
		</cfscript>
	</cffunction>

	<cffunction name="getAdminUserDetails" access="public" returntype="struct" output="false">
		<cfreturn getModel( "loginService" ).getLoggedInUserDetails() />
	</cffunction>

	<cffunction name="getAdminUserId" access="public" returntype="string" output="false">
		<cfreturn getModel( "loginService" ).getLoggedInUserId() />
	</cffunction>

	<cffunction name="adminAccessDenied" access="public" returntype="void" output="false">
		<cfscript>
			// todo, something much better here!
			content reset=true type="text/html";header statusCode="401";WriteOutput("<h1>Access denied</h1>");abort;
		</cfscript>
	</cffunction>

	<cffunction name="audit" access="public" returntype="void" output="false">
		<cfscript>
			arguments.userId = getAdminUserId();

			return getModel( "AuditService" ).log( argumentCollection = arguments );
		</cfscript>
	</cffunction>

	<cffunction name="addAdminBreadCrumb" access="public" returntype="void" output="false">
		<cfargument name="title" type="string" required="true" />
		<cfargument name="link"  type="string" required="true" />

		<cfscript>
			var event  = getRequestContext();
			var crumbs = event.getValue( name="_adminBreadCrumbs", defaultValue=[], private=true );

			ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

			event.setValue( name="_adminBreadCrumbs", value=crumbs, private=true );
		</cfscript>
	</cffunction>

	<cffunction name="getAdminBreadCrumbs" access="public" returntype="array" output="false">
		<cfreturn getRequestContext().getValue( name="_adminBreadCrumbs", defaultValue=[], private=true ) />
	</cffunction>

	<cffunction name="getHTTPContent" access="public" returntype="string" output="false">
		<cfreturn request.http.body ?: ToString( getHTTPRequestData().content ) />
	</cffunction>

<!--- Sticker --->
	<cffunction name="include" access="public" returntype="any" output="false">
		<cfreturn _getSticker().include( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="includeData" access="public" returntype="any" output="false">
		<cfreturn _getSticker().includeData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false">
		<cfargument name="type" type="string" required="false" />
		<cfscript>
			var rendered      = _getSticker().renderIncludes( argumentCollection = arguments );
			var inlineJsArray = "";

			if ( not StructKeyExists( arguments, "type" ) or arguments.type eq "js" ) {
				var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );
				rendered &= ArrayToList( inlineJsArray, Chr(10) );
				getRequestContext().setValue( name="__presideInlineJsArray", value=[], private=true );
			}

			return rendered;
		</cfscript>
	</cffunction>

	<cffunction name="includeInlineJs" access="public" returntype="void" output="false">
		<cfargument name="js" type="string" required="true" />
		<cfscript>
			var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );

			ArrayAppend( inlineJsArray, "<script type=""text/javascript"">" & Chr(10) & arguments.js & Chr(10) & "</script>" );

			getRequestContext().setValue( name="__presideInlineJsArray", value=inlineJsArray, private=true );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getSticker" access="private" returntype="any" output="false">
		<cfreturn getController().getPlugin(
			  plugin       = "StickerForPreside"
			, customPlugin = true
		) />
	</cffunction>

	<cffunction name="getModel" access="private" returntype="any" output="false">
		<cfargument name="beanName" type="string" required="true" />

		<cfreturn getController().getWireBox().getInstance( arguments.beanName ) />
	</cffunction>

	<cffunction name="announceInterception" access="public" returntype="any" output="false">
		<cfreturn getController().getInterceptorService().processState( argumentCollection=arguments ) />
	</cffunction>

<!--- security helpers --->
	<cffunction name="getCsrfToken" access="public" returntype="string" output="false">
		<cfreturn getModel( "csrfProtectionService" ).generateToken( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="validateCsrfToken" access="public" returntype="string" output="false">
		<cfreturn getModel( "csrfProtectionService" ).validateToken( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="isActionRequest" access="public" returntype="boolean" output="false">
		<cfargument name="ev" type="string" required="false" default="#getRequestContext().getCurrentEvent()#" />
		<cfscript>
			var currentEvent = LCase( arguments.ev );

			if ( ReFind( "^admin\.ajaxProxy\..*?", currentEvent ) ) {
				currentEvent = "admin." & LCase( event.getValue( "action", "" ) );
			}

			return ReFind( "^admin\..*?action$", currentEvent );
		</cfscript>
	</cffunction>

<!--- FRONT END, dealing with current page --->
	<cffunction name="initializePresideSiteteePage" access="public" returntype="void" output="false">
		<cfargument name="slug"       type="string" required="false" />
		<cfargument name="pageId"     type="string" required="false" />
		<cfargument name="systemPage" type="string" required="false" />
		<cfargument name="subaction"  type="string" required="false" />

		<cfscript>
			var sitetreeSvc = getModel( "sitetreeService" );
			var rc          = getRequestContext().getCollection();
			var prc         = getRequestContext().getCollection( private = true );
			var page        = "";
			var parentPages = "";
			var getPageArgs = {};
			var isActive    = function( required boolean active, required string embargo_date, required string expiry_date ) {
				return arguments.active && ( !IsDate( arguments.embargo_date ) || Now() >= arguments.embargo_date ) && ( !IsDate( arguments.expiry_date ) || Now() <= arguments.expiry_date );
			}

			if ( ( arguments.slug ?: "/" ) == "/" && !Len( Trim( arguments.pageId ?: "" ) ) && !Len( Trim( arguments.systemPage ?: "" ) ) ) {
				page = sitetreeSvc.getSiteHomepage();
				parentPages = QueryNew( page.columnlist );
			} else {
				if ( Len( Trim( arguments.pageId ?: "" ) ) ) {
					getPageArgs.id = arguments.pageId;
				} elseif ( Len( Trim( arguments.systemPage ?: "" ) ) ) {
					getPageArgs.systemPage = arguments.systemPage;
				} else {
					getPageArgs.slug = arguments.slug;
				}
				page = sitetreeSvc.getPage( argumentCollection = getPageArgs );
			}

			if ( not page.recordCount ) {
				return;
			}

			for( p in page ){ page = p; break; } // quick query row to struct hack

			StructAppend( page, sitetreeSvc.getExtendedPageProperties( page.id, page.page_type ) );
			var ancestors = sitetreeSvc.getAncestors( id = page.id );
			page.ancestors = [];

			page.ancestorList = ancestors.recordCount ? ValueList( ancestors.id ) : "";
			page.permissionContext = [ page.id ];
			for( var i=ListLen( page.ancestorList ); i > 0; i-- ){
				page.permissionContext.append( ListGetAt( page.ancestorList, i ) );
			}

			clearBreadCrumbs();
			for( var ancestor in ancestors ) {
				addBreadCrumb( title=ancestor.title, link=buildLink( page=ancestor.id ) );
				page.ancestors.append( ancestor );
			}
			addBreadCrumb( title=page.title, link=buildLink( page=page.id ) );

			page.isInDateAndActive = isActive( argumentCollection = page );
			if ( page.isInDateAndActive ) {
				for( var ancestor in page.ancestors ) {
					page.isInDateAndActive = isActive( argumentCollection = ancestor );
					if ( !page.isInDateAndActive ) {
						break;
					}
				}
			}

			page.access_providing_page = page.id;
			if ( ( page.access_restriction ?: "inherit" ) == "inherit" ) {
				for( var ancestor in page.ancestors ) {
					if ( ( ancestor.access_restriction ?: "inherit" ) != "inherit" ) {
						page.access_providing_page = ancestor.id;
						page.access_restriction = ancestor.access_restriction;
						page.full_login_required = ancestor.full_login_required;
						break;
					}
				}
			}
			if ( ( page.access_restriction ?: "inherit" ) == "inherit" ) {
				page.access_restriction = "none";
			}

			p[ "slug" ] = p._hierarchy_slug;
			StructDelete( p, "_hierarchy_slug" );

			prc.presidePage = page;
		</cfscript>
	</cffunction>

	<cffunction name="initializeDummyPresideSiteTreePage" access="public" returntype="void" output="false">
		<cfscript>
			var sitetreeSvc = getModel( "sitetreeService" );
			var rc          = getRequestContext().getCollection();
			var prc         = getRequestContext().getCollection( private = true );
			var page        = Duplicate( arguments );
			var parentPages = "";

			page.ancestors = [];

			clearBreadCrumbs();

			if ( !IsNull( arguments.parentpage ?: NullValue() ) && arguments.parentPage.recordCount ) {
				page.parent_page = arguments.parentPage.id;

				var ancestors = sitetreeSvc.getAncestors( id = arguments.parentPage.id );

				page.ancestorList = ancestors.recordCount ? ValueList( ancestors.id ) : "";
				page.ancestorList = ListAppend( page.ancestorList, arguments.parentPage.id );

				page.permissionContext = [];
				for( var i=ListLen( page.ancestorList ); i > 0; i-- ){
					page.permissionContext.append( ListGetAt( page.ancestorList, i ) );
				}

				for( var ancestor in ancestors ) {
					addBreadCrumb( title=ancestor.title, link=buildLink( page=ancestor.id ) );
					page.ancestors.append( ancestor );
				}
				for( var p in arguments.parentPage ){
					addBreadCrumb( title=p.title, link=buildLink( page=p.id ) );
					page.ancestors.append( p );
				}
			}

			addBreadCrumb( title=page.title ?: "", link=getCurrentUrl() );

			prc.presidePage = page;
		</cfscript>
	</cffunction>

	<cffunction name="checkPageAccess" access="public" returntype="void" output="false">
		<cfscript>
			if ( getPageProperty( "access_restriction", "none" ) == "full" ){
				var websiteLoginService = getModel( "websiteLoginService" );
				var fullLoginRequired = getPageProperty( "full_login_required", false );
				var loggedIn          = websiteLoginService.isLoggedIn() && (!fullLoginRequired || !websiteLoginService.isAutoLoggedIn() );

				if ( !loggedIn ) {
					accessDenied( reason="LOGIN_REQUIRED" );
				}

				var accessProvidingPage = getPageProperty( "access_providing_page", getCurrentPageId() );
				var hasPermission       = getModel( "websitePermissionService" ).hasPermission(
					  permissionKey = "pages.access"
					, context       = "page"
					, contextKeys   = [ accessProvidingPage ]
				);

				if ( !hasPermission ) {
					accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="getPageProperty" access="public" returntype="any" output="false">
		<cfargument name="propertyName"     type="string"  required="true" />
		<cfargument name="defaultValue"     type="any"     required="false" default="" />
		<cfargument name="cascading"        type="boolean" required="false" default="false" />
		<cfargument name="cascadeMethod"    type="string"  required="false" default="closest" hint="closest|collect" />
		<cfargument name="cascadeSkipValue" type="string"  required="false" default="inherit" />

		<cfscript>
			var page = getRequestContext().getValue( name="presidePage", defaultValue=StructNew(), private=true );

			if ( StructIsEmpty( page ) ) {
				return arguments.defaultValue;
			}

			if ( IsBoolean( page.isApplicationPage ?: "" ) && page.isApplicationPage ) {
				if ( arguments.cascading ) {
					var cascadeSearch = Duplicate( page.ancestors ?: [] );
					cascadeSearch.prepend( page );

					if ( arguments.cascadeMethod == "collect" ) {
						var collected = [];
					}
					for( node in cascadeSearch ){
						if ( Len( Trim( node[ arguments.propertyName ] ?: "" ) ) && node[ arguments.propertyName ] != arguments.cascadeSkipValue ) {
							if ( arguments.cascadeMethod != "collect" ) {
								return node[ arguments.propertyName ];
							}
							collected.append( node[ arguments.propertyName ] );
						}
					}

					if ( arguments.cascadeMethod == "collect" ) {
						return collected;
					}

					return arguments.defaultValue;
				}

				return page[ arguments.propertyName ] ?: arguments.defaultValue;
			}

			return getModel( "sitetreeService" ).getPageProperty(
				  propertyName  = arguments.propertyName
				, page          = page
				, ancestors     = page.ancestors ?: []
				, defaultValue  = arguments.defaultValue
				, cascading     = arguments.cascading
				, cascadeMethod = arguments.cascadeMethod
			);
		</cfscript>
	</cffunction>

	<cffunction name="getCurrentPageType" access="public" returntype="string" output="false">
		<cfreturn getPageProperty( 'page_type' ) />
	</cffunction>

	<cffunction name="getCurrentTemplate" access="public" returntype="string" output="false">
		<cfreturn getPageProperty( 'page_template' ) />
	</cffunction>

	<cffunction name="getCurrentPageId" access="public" returntype="string" output="false">
		<cfreturn getPageProperty( 'id' ) />
	</cffunction>

	<cffunction name="isCurrentPageActive" access="public" returntype="boolean" output="false">
		<cfreturn getPageProperty( 'isInDateAndActive', false ) />
	</cffunction>

	<cffunction name="getPagePermissionContext" access="public" returntype="array" output="false">
		<cfreturn getPageProperty( "permissionContext", [] ) />
	</cffunction>

	<cffunction name="addBreadCrumb" access="public" returntype="void" output="false">
		<cfargument name="title" type="string" required="true" />
		<cfargument name="link"  type="string" required="true" />

		<cfscript>
			var crumbs = getBreadCrumbs();

			ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

			getRequestContext().setValue( name="_breadCrumbs", value=crumbs, private=true );
		</cfscript>
	</cffunction>

	<cffunction name="getBreadCrumbs" access="public" returntype="array" output="false">
		<cfreturn getRequestContext().getValue( name="_breadCrumbs", defaultValue=[], private=true ) />
	</cffunction>

	<cffunction name="clearBreadCrumbs" access="public" returntype="void" output="false">
		<cfset getRequestContext().setValue( name="_breadCrumbs", value=[], private=true ) />
	</cffunction>

	<cffunction name="getEditPageLink" access="public" returntype="string" output="false">
		<cfscript>
			var prc = getRequestContext().getCollection( private=true );

			if ( !prc.keyExists( "_presideCmsEditPageLink" ) ) {
				setEditPageLink( buildAdminLink( linkTo='sitetree.editPage', queryString='id=#getCurrentPageId()#' ) );
			}

			return prc._presideCmsEditPageLink;
		</cfscript>
	</cffunction>
	<cffunction name="setEditPageLink" access="public" returntype="void" output="false">
		<cfargument name="editPageLink" type="string" required="true" />

		<cfset getRequestContext().setValue( name="_presideCmsEditPageLink", value=arguments.editPageLink, private=true ) />
	</cffunction>

<!--- status codes --->
	<cffunction name="notFound" access="public" returntype="void" output="false">
		<cfscript>
			announceInterception( "onNotFound" );
			getController().runEvent( "general.notFound" );
			content reset=true type="text/html";header statusCode="404";WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
		</cfscript>
	</cffunction>

	<cffunction name="accessDenied" access="public" returntype="void" output="false">
		<cfargument name="reason" type="string" required="true" />

		<cfscript>
			announceInterception( "onAccessDenied" , arguments );
			getController().runEvent( event="general.accessDenied", eventArguments={ args=arguments } );
			WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_structToQueryString" access="public" returntype="string" output="false">
		<cfargument name="inputStruct" type="struct" required="true" />

		<cfscript>
			var qs    = "";
			var delim = "";

			for( var key in inputStruct ){
				if ( IsSimpleValue( inputStruct[ key ] ) ) {
					qs &= delim & key & "=" & inputStruct[ key ];
					delim = "&";
				}
			}

			return qs;
		</cfscript>
	</cffunction>
</cfcomponent>
