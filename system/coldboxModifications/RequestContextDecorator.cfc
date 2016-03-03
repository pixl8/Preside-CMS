/**
 *	Helper methods and standard event method overrides that are specific to Preside
 *	live here.
 */
component extends="coldbox.system.web.context.RequestContextDecorator" output=false {

/*
 * NOTE: Because this CFC is merged with a tag based CFC file
 * the output=false declarations on all the functions are all *necessary*!
 * Do not remove them unless you are fully aware that this issue is no
 * longer a problem.
 *
 * Dominic
 *
 */

// URL related
	public void function setSite( required struct site ) output=false {
		getRequestContext().setValue(
			  name    = "_site"
			, value   =  arguments.site
			, private =  true
		);
	}

	public struct function getSite() output=false {
		var site = getRequestContext().getValue( name="_site", private=true, defaultValue={} );

		if ( IsStruct( site ) ) {
			return site;
		}

		return {};
	}

	public string function getSiteUrl( string siteId="", boolean includePath=true ) output=false {
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

	public string function getSystemPageId( required string systemPage ) output=false {
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

	public string function getSiteId() output=false {
		var site = getSite();

		return site.id ?: "";
	}

	public string function buildLink() output=false {
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

	public string function getProtocol() output=false {
		return cgi.server_protocol contains "https" ? "https" : "http";
	}

	public string function getServerName() output=false {
		return cgi.server_name;
	}

	public string function getBaseUrl() output=false {
		return getProtocol() & "://" & getServerName();
	}

	public struct function getCollectionWithoutSystemVars() output=false {
		var collection = Duplicate( getRequestContext().getCollection() );

		StructDelete( collection, "csrfToken"   );
		StructDelete( collection, "action"      );
		StructDelete( collection, "event"       );
		StructDelete( collection, "handler"     );
		StructDelete( collection, "module"      );
		StructDelete( collection, "fieldnames"  );

		return collection;
	}

	public struct function getCollectionForForm( required string formName ) output=false {
		var formFields = getModel( "formsService" ).listFields( arguments.formName );
		var collection = {};
		var rc         = getRequestContext().getCollection();

		for( var field in formFields ){
			collection[ field ] = ( rc[ field ] ?: "" );
		}

		return collection;
	}

// Admin specific
	public string function buildAdminLink( string linkTo="", string queryString="" ) output=false {
		arguments.linkTo = ListAppend( "admin", arguments.linkTo, "." );

		if ( isActionRequest( arguments.linkTo ) ) {
			arguments.queryString = ListAppend( arguments.queryString, "csrfToken=" & this.getCsrfToken(), "&" );
		}

		return buildLink( argumentCollection = arguments );
	}

	public string function getAdminPath() output=false {
		var overridenSetting = getModel( "systemConfigurationService" ).getSetting( "general", "admin_url" );
		var path             = Len( Trim( overridenSetting ) ) ? overridenSetting : getController().getSetting( "preside_admin_path" );

		return Len( Trim( path ) ) ? "/#path#/" : "/";
	}

	public string function getCurrentUrl( boolean includeQueryString=true ) output=false {
		var currentUrl  = request[ "preside.path_info"    ] ?: "";
		var qs          = request[ "preside.query_string" ] ?: "";
		var includeQs   = arguments.includeQueryString && Len( Trim( qs ) );

		return includeQs ? currentUrl & "?" & qs : currentUrl;
	}

	public boolean function isAdminRequest() output=false {
		var currentUrl = getCurrentUrl();
		var adminPath  = getAdminPath();

		return currentUrl.startsWith( adminPath );
	}

	public boolean function isAdminUser() output=false {
		var loginSvc = getModel( "loginService" );

		return loginSvc.isLoggedIn();
	}

	public struct function getAdminUserDetails() output=false {
		return getModel( "loginService" ).getLoggedInUserDetails();
	}

	public string function getAdminUserId() output=false {
		return getModel( "loginService" ).getLoggedInUserId();
	}

	public void function adminAccessDenied() output=false {
		var event = getRequestContext();

		announceInterception( "onAccessDenied" , arguments );

		event.setView( view="/admin/errorPages/accessDenied" );
		event.setLayout( "admin" );

		event.setHTTPHeader( statusCode="401" );
		event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
		event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

		content reset=true type="text/html";header statusCode="401";WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
	}

	public void function audit() output=false {
		arguments.userId = getAdminUserId();

		return getModel( "AuditService" ).log( argumentCollection = arguments );
	}

	public void function addAdminBreadCrumb( required string title, required string link ) output=false {
		var event  = getRequestContext();
		var crumbs = event.getValue( name="_adminBreadCrumbs", defaultValue=[], private=true );

		ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

		event.setValue( name="_adminBreadCrumbs", value=crumbs, private=true );
	}

	public array function getAdminBreadCrumbs() output=false {
		return getRequestContext().getValue( name="_adminBreadCrumbs", defaultValue=[], private=true );
	}

	public string function getHTTPContent() output=false {
		return request.http.body ?: ToString( getHTTPRequestData().content );
	}

// Sticker
	public any function include() output=false {
		return _getSticker().include( argumentCollection = arguments );
	}

	public any function includeData() output=false {
		return _getSticker().includeData( argumentCollection = arguments );
	}

	public string function renderIncludes( string type ) output=false {
		var rendered      = _getSticker().renderIncludes( argumentCollection = arguments );
		var inlineJsArray = "";

		if ( not StructKeyExists( arguments, "type" ) or arguments.type eq "js" ) {
			var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );
			rendered &= ArrayToList( inlineJsArray, Chr(10) );
			getRequestContext().setValue( name="__presideInlineJsArray", value=[], private=true );
		}

		return rendered;
	}

	public void function includeInlineJs( required string js ) output=false {
		var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );

		ArrayAppend( inlineJsArray, "<script type=""text/javascript"">" & Chr(10) & arguments.js & Chr(10) & "</script>" );

		getRequestContext().setValue( name="__presideInlineJsArray", value=inlineJsArray, private=true );
	}

// private helpers
	public any function _getSticker() output=false {
		return getController().getPlugin(
			  plugin       = "StickerForPreside"
			, customPlugin = true
		);
	}

	public any function getModel( required string beanName ) output=false {
		return getController().getWireBox().getInstance( arguments.beanName );
	}

	public any function announceInterception() output=false {
		return getController().getInterceptorService().processState( argumentCollection=arguments );
	}

// security helpers
	public string function getCsrfToken() output=false {
		return getModel( "csrfProtectionService" ).generateToken( argumentCollection = arguments );
	}

	public string function validateCsrfToken() output=false {
		return getModel( "csrfProtectionService" ).validateToken( argumentCollection = arguments );
	}

	public boolean function isActionRequest( string ev=getRequestContext().getCurrentEvent() ) output=false {
		var currentEvent = LCase( arguments.ev );

		if ( ReFind( "^admin\.ajaxProxy\..*?", currentEvent ) ) {
			currentEvent = "admin." & LCase( event.getValue( "action", "" ) );
		}

		return ReFind( "^admin\..*?action$", currentEvent );
	}

	public void function setXFrameOptionsHeader( string value ) {
		if ( !StructKeyExists( arguments, "value" ) ) {
			var setting = getPageProperty( propertyName="iframe_restriction", cascading=true );
			switch( setting ) {
				case "allow":
					return; // do not set any header
				case "sameorigin":
					arguments.value = "SAMEORIGIN";
					break;
				default:
					arguments.value = "DENY";
			}
		}

		getRequestContext().setHTTPHeader( name="X-Frame-Options", value=arguments.value );
	}

// FRONT END, dealing with current page
	public void function initializePresideSiteteePage (
		  string slug
		, string pageId
		, string systemPage
		, string subaction
	) output=false {
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

	public void function initializeDummyPresideSiteTreePage() output=false {
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

	public void function checkPageAccess() output=false {
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

	public struct function getPageAccessRules() output=false {
		var prc = getRequestContext().getCollection( private = true );

		if ( !prc.keyExists( "pageAccessRules" ) ) {
			prc.pageAccessRules = getModel( "sitetreeService" ).getAccessRestrictionRulesForPage( getCurrentPageId() );
		}

		return prc.pageAccessRules;
	}

	public void function preventPageCache() output=false {
		header name="cache-control" value="no-cache, no-store";
		header name="expires"       value="Fri, 20 Nov 2015 00:00:00 GMT";
	}

	public boolean function canPageBeCached() output=false {
		if ( getModel( "websiteLoginService" ).isLoggedIn() || this.isAdminUser() ) {
			return false;
		}

		var accessRules = getPageAccessRules();

		return ( accessRules.access_restriction ?: "none" ) == "none";
	}

	public any function getPageProperty (
		  required string  propertyName
		,          any     defaultValue     = ""
		,          boolean cascading        = false
		,          string  cascadeMethod    = "closest"
		,          string  cascadeSkipValue = "inherit"
	) output=false {

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

	public string function getCurrentPageType() output=false {
		return getPageProperty( 'page_type' );
	}

	public string function getCurrentTemplate() output=false {
		return getPageProperty( 'page_template' );
	}

	public string function getCurrentPageId() output=false {
		return getPageProperty( 'id' );
	}

	public boolean function isCurrentPageActive() output=false {
		return getPageProperty( 'isInDateAndActive', false );
	}

	public array function getPagePermissionContext() output=false {
		return getPageProperty( "permissionContext", [] );
	}

	public void function addBreadCrumb( required string title, required string link ) output=false {
		var crumbs = getBreadCrumbs();

		ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

		getRequestContext().setValue( name="_breadCrumbs", value=crumbs, private=true );
	}

	public array function getBreadCrumbs() output=false {
		return getRequestContext().getValue( name="_breadCrumbs", defaultValue=[], private=true );
	}

	public void function clearBreadCrumbs() output=false {
		getRequestContext().setValue( name="_breadCrumbs", value=[], private=true );
	}

	public string function getEditPageLink() output=false {
		var prc = getRequestContext().getCollection( private=true );

		if ( !prc.keyExists( "_presideCmsEditPageLink" ) ) {
			setEditPageLink( buildAdminLink( linkTo='sitetree.editPage', queryString='id=#getCurrentPageId()#' ) );
		}

		return prc._presideCmsEditPageLink;
	}
	public void function setEditPageLink( required string editPageLink ) output=false {
		getRequestContext().setValue( name="_presideCmsEditPageLink", value=arguments.editPageLink, private=true );
	}

<!--- FRONT END - Multilingual helpers --->
	public string function getLanguage() output=false {
		return getRequestContext().getValue( name="_language", defaultValue="", private=true );
	}
	public void function setLanguage( required string language ) output=false {
		getRequestContext().setValue( name="_language", value=arguments.language, private=true );
	}

<!--- status codes --->
	public void function notFound() output=false {
		announceInterception( "onNotFound" );
		getController().runEvent( "general.notFound" );
		content reset=true type="text/html";header statusCode="404";WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
	}

	public void function accessDenied( required string reason ) output=false {
		announceInterception( "onAccessDenied" , arguments );
		getController().runEvent( event="general.accessDenied", eventArguments={ args=arguments } );
		WriteOutput( getController().getPlugin("Renderer").renderLayout() );abort;
	}

<!--- private helpers --->
	public string function _structToQueryString( required struct inputStruct ) output=false {
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