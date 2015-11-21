/**
 *	Helper methods and standard event method overrides that are specific to Preside
 *	live here.
 */

component extends="coldbox.system.web.context.RequestContextDecorator" {
// URL related
	public void function setSite( required struct site ) {
		getRequestContext().setValue(
			  name    = "_site"
			, value   =  arguments.site
			, private =  true
		);
	}

	public struct function getSite() {
		var site = getRequestContext().getValue( name="_site", private=true, defaultValue={} );

		if ( IsStruct( site ) ) {
			return site;
		}

		return {};
	}

	public string function getSiteUrl( string siteId="", boolean includePath=true ) {
		var fetchSite = Len( Trim( arguments.siteId ) ) && arguments.siteId != getSiteId();
		var site      = fetchSite ? getModel( "siteService" ).getSite( arguments.siteId ) : getSite();
		var siteUrl   = ( site.protocol ?: "http" ) & "://" & ( site.domain ?: cgi.server_name );

		if ( cgi.server_port != 80 ) {
			siteUrl &= ":#cgi.server_port#";
		}

		if ( arguments.includePath ) {
			siteUrl &= site.path ?: "/";
		}

		return siteUrl;
	}

	public string function getSystemPageId( required string systemPage ) {
		var sitetreeSvc = getModel( "sitetreeService" );
		var page        = sitetreeSvc.getPage(
			  systemPage   = arguments.systemPage
				, selectFields = [ "id" ]
		);

		if ( not page.recordCount ) {
			return "";
		}
		return page.id;
	}

	public string function getSiteId() {
		var site = getSite();

		return site.id ?: "";
	}

	public string function buildLink() {
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
	}

	public string function getProtocol() {
		return cgi.server_protocol contains "https" ? "https" : "http";
	}

	public string function getServerName() {
		return cgi.server_name;
	}

	public string function getBaseUrl() {
		return getProtocol() & "://" & getServerName();
	}

	public struct function getCollectionWithoutSystemVars() {
		var collection = Duplicate( getRequestContext().getCollection() );

		StructDelete( collection, "csrfToken"   );
		StructDelete( collection, "action"      );
		StructDelete( collection, "event"       );
		StructDelete( collection, "handler"     );
		StructDelete( collection, "module"      );
		StructDelete( collection, "fieldnames"  );

		return collection;
	}

	public struct function getCollectionForForm( required string formName ) {
		var formFields = getModel( "formsService" ).listFields( arguments.formName );
		var collection = {};
		var rc         = getRequestContext().getCollection();

		for( var field in formFields ){
			collection[ field ] = ( rc[ field ] ?: "" );
		}

		return collection;
	}

// Admin specific
	public string function buildAdminLink( string linkTo="", string queryString="" ) {
		arguments.linkTo = ListAppend( "admin", arguments.linkTo, "." );

		if ( isActionRequest( arguments.linkTo ) ) {
			arguments.queryString = ListAppend( arguments.queryString, "csrfToken=" & this.getCsrfToken(), "&" );
		}

		return buildLink( argumentCollection = arguments );
	}

	public string function getAdminPath() {
		var overridenSetting = getModel( "systemConfigurationService" ).getSetting( "general", "admin_url" );
		var path             = Len( Trim( overridenSetting ) ) ? overridenSetting : getController().getSetting( "preside_admin_path" );

		return Len( Trim( path ) ) ? "/#path#/" : "/";
	}

	public string function getCurrentUrl( boolean includeQueryString=true ) {
		var currentUrl  = request[ "preside.path_info"    ] ?: "";
		var qs          = request[ "preside.query_string" ] ?: "";
		var includeQs   = arguments.includeQueryString && Len( Trim( qs ) );

		return includeQs ? currentUrl & "?" & qs : currentUrl;
	}

	public boolean function isAdminRequest() {
		var currentUrl = getCurrentUrl();
		var adminPath  = getAdminPath();

		return currentUrl.startsWith( adminPath );
	}

	public boolean function isAdminUser() {
		var loginSvc = getModel( "loginService" );

		return loginSvc.isLoggedIn();
	}

	public struct function getAdminUserDetails() {
		return getModel( "loginService" ).getLoggedInUserDetails();
	}

	public string function getAdminUserId() {
		return getModel( "loginService" ).getLoggedInUserId();
	}

	public void function adminAccessDenied() {
		var event = getRequestContext();

		announceInterception( "onAccessDenied" , arguments );

		event.setView( view="/admin/errorPages/accessDenied" );
		event.setLayout( "admin" );

		event.setHTTPHeader( statusCode="401" );
		event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
		event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

		content reset=true type="text/html";header statusCode="401";WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
	}

	public void function audit() {
		arguments.userId = getAdminUserId();

		return getModel( "AuditService" ).log( argumentCollection = arguments );
	}

	public void function addAdminBreadCrumb( required string title, required string link ) {
		var event  = getRequestContext();
		var crumbs = event.getValue( name="_adminBreadCrumbs", defaultValue=[], private=true );

		ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

		event.setValue( name="_adminBreadCrumbs", value=crumbs, private=true );
	}

	public array function getAdminBreadCrumbs() {
		return getRequestContext().getValue( name="_adminBreadCrumbs", defaultValue=[], private=true );
	}

	public string function getHTTPContent() {
		return request.http.body ?: ToString( getHTTPRequestData().content );
	}

// Sticker
	public any function include() {
		return _getSticker().include( argumentCollection = arguments );
	}

	public any function includeData() {
		return _getSticker().includeData( argumentCollection = arguments );
	}

	public string function renderIncludes( string type ) {
		var rendered      = _getSticker().renderIncludes( argumentCollection = arguments );
		var inlineJsArray = "";

		if ( not StructKeyExists( arguments, "type" ) or arguments.type eq "js" ) {
			var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );
			rendered &= ArrayToList( inlineJsArray, Chr(10) );
			getRequestContext().setValue( name="__presideInlineJsArray", value=[], private=true );
		}

		return rendered;
	}

	public void function includeInlineJs( required string js ) {
		var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );

		ArrayAppend( inlineJsArray, "<script type=""text/javascript"">" & Chr(10) & arguments.js & Chr(10) & "</script>" );

		getRequestContext().setValue( name="__presideInlineJsArray", value=inlineJsArray, private=true );
	}

// private helpers
	public any function _getSticker() {
		return getController().getPlugin(
			  plugin       = "StickerForPreside"
			, customPlugin = true
		);
	}

	public any function getModel( required string beanName ) {
		return getController().getWireBox().getInstance( arguments.beanName );
	}

	public any function announceInterception() {
		return getController().getInterceptorService().processState( argumentCollection=arguments );
	}

// security helpers
	public string function getCsrfToken() {
		return getModel( "csrfProtectionService" ).generateToken( argumentCollection = arguments );
	}

	public string function validateCsrfToken() {
		return getModel( "csrfProtectionService" ).validateToken( argumentCollection = arguments );
	}

	public boolean function isActionRequest( string ev=getRequestContext().getCurrentEvent() ) {
		var currentEvent = LCase( arguments.ev );

		if ( ReFind( "^admin\.ajaxProxy\..*?", currentEvent ) ) {
			currentEvent = "admin." & LCase( event.getValue( "action", "" ) );
		}

		return ReFind( "^admin\..*?action$", currentEvent );
	}

// FRONT END, dealing with current page
	public void function initializePresideSiteteePage(
		  string slug
		, string pageId
		, string systemPage
		, string subaction
	) {
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

		p[ "slug" ] = p._hierarchy_slug;
		StructDelete( p, "_hierarchy_slug" );

		prc.presidePage = page;
	}

	public void function initializeDummyPresideSiteTreePage() {
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
	}

	public void function checkPageAccess() {
		var websiteLoginService = getModel( "websiteLoginService" );
		var accessRules         = getPageAccessRules();

		if ( accessRules.access_restriction == "full" ){
			var fullLoginRequired = IsBoolean( accessRules.full_login_required ) && accessRules.full_login_required;
			var loggedIn          = websiteLoginService.isLoggedIn() && (!fullLoginRequired || !websiteLoginService.isAutoLoggedIn() );

			if ( !loggedIn ) {
				accessDenied( reason="LOGIN_REQUIRED" );
			}

			hasPermission = getModel( "websitePermissionService" ).hasPermission(
				  permissionKey       = "pages.access"
				, context             = "page"
				, contextKeys         = [ accessRules.access_defining_page ]
				, forceGrantByDefault = IsBoolean( accessRules.grantaccess_to_all_logged_in_users ) && accessRules.grantaccess_to_all_logged_in_users
			);

			if ( !hasPermission ) {
				accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
			}
		}
	}

	public struct function getPageAccessRules() {
		var prc = getRequestContext().getCollection( private = true );

		if ( !prc.keyExists( "pageAccessRules" ) ) {
			prc.pageAccessRules = getModel( "sitetreeService" ).getAccessRestrictionRulesForPage( getCurrentPageId() );
		}

		return prc.pageAccessRules;
	}

	public boolean function canPageBeCached() {
		var accessRules = getPageAccessRules();

		return ( accessRules.access_restriction ?: "none" ) == "none";
	}

	public any function getPageProperty(
		  required string  propertyName
		,          any     defaultValue     = ""
		,          boolean cascading        = false
		,          string  cascadeMethod    = "closest"
		,          string  cascadeSkipValue = "inherit"
	) {

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
	}

	public string function getCurrentPageType() {
		return getPageProperty( 'page_type' );
	}

	public string function getCurrentTemplate() {
		return getPageProperty( 'page_template' );
	}

	public string function getCurrentPageId() {
		return getPageProperty( 'id' );
	}

	public boolean function isCurrentPageActive() {
		return getPageProperty( 'isInDateAndActive', false );
	}

	public array function getPagePermissionContext() {
		return getPageProperty( "permissionContext", [] );
	}

	public void function addBreadCrumb( required string title, required string link ) {
		var crumbs = getBreadCrumbs();

		ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

		getRequestContext().setValue( name="_breadCrumbs", value=crumbs, private=true );
	}

	public array function getBreadCrumbs() {
		return getRequestContext().getValue( name="_breadCrumbs", defaultValue=[], private=true );
	}

	public void function clearBreadCrumbs() {
		getRequestContext().setValue( name="_breadCrumbs", value=[], private=true );
	}

	public string function getEditPageLink() {
		var prc = getRequestContext().getCollection( private=true );

		if ( !prc.keyExists( "_presideCmsEditPageLink" ) ) {
			setEditPageLink( buildAdminLink( linkTo='sitetree.editPage', queryString='id=#getCurrentPageId()#' ) );
		}

		return prc._presideCmsEditPageLink;
	}
	public void function setEditPageLink( required string editPageLink ) {
		getRequestContext().setValue( name="_presideCmsEditPageLink", value=arguments.editPageLink, private=true );
	}

<!--- FRONT END - Multilingual helpers --->
	public string function getLanguage() {
		return getRequestContext().getValue( name="_language", defaultValue="", private=true );
	}
	public void function setLanguage( required string language ) {
		getRequestContext().setValue( name="_language", value=arguments.language, private=true );
	}

<!--- status codes --->
	public void function notFound() {
		announceInterception( "onNotFound" );
		getController().runEvent( "general.notFound" );
		content reset=true type="text/html";header statusCode="404";WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
	}

	public void function accessDenied( required string reason ) {
		announceInterception( "onAccessDenied" , arguments );
		getController().runEvent( event="general.accessDenied", eventArguments={ args=arguments } );
		WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
	}

<!--- private helpers --->
	public string function _structToQueryString( required struct inputStruct ) {
		var qs    = "";
		var delim = "";

		for( var key in inputStruct ){
			if ( IsSimpleValue( inputStruct[ key ] ) ) {
				qs &= delim & key & "=" & inputStruct[ key ];
				delim = "&";
			}
		}

		return qs;
	}
}