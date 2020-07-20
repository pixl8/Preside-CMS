/**
 *	Helper methods and standard event method overrides that are specific to Preside
 *	live here.
 */
component accessors=true extends="preside.system.coldboxModifications.RequestContext" {

	// The original request context
	property name="requestContext";

	/**
	* Constructor
	*/
	RequestContextDecorator function init( required oContext, required controller ){
		// Set the memento state
		setMemento( arguments.oContext.getMemento() );
		// Set Controller+wirebox
		instance.controller = arguments.controller;
		instance.wirebox    = instance.controller.getWireBox();

		// Composite the original context
		variables.requestContext = arguments.oContext;


		return this;
	}

	/**
	* Override to provide a pseudo-constructor for your decorator
	*/
	function configure(){

		instance.adminObjectLinkBuilderService    = instance.wirebox.getInstance( "adminObjectLinkBuilderService" );
		instance.auditService                     = instance.wirebox.getInstance( "auditService" );
		instance.csrfProtectionService            = instance.wirebox.getInstance( "csrfProtectionService" );
		instance.delayedStickerRendererService    = instance.wirebox.getInstance( "delayedStickerRendererService" );
		instance.delayedViewletRendererService    = instance.wirebox.getInstance( "delayedViewletRendererService" );
		instance.featureService                   = instance.wirebox.getInstance( "featureService" );
		instance.formsService                     = instance.wirebox.getInstance( "formsService" );
		instance.i18n                             = instance.wirebox.getInstance( "i18n" );
		instance.loginService                     = instance.wirebox.getInstance( "loginService" );
		instance.multilingualPresideObjectService = instance.wirebox.getInstance( "multilingualPresideObjectService" );
		instance.presideRenderer                  = instance.wirebox.getInstance( "presideRenderer" );
		instance.rulesEngineWebRequestService     = instance.wirebox.getInstance( "rulesEngineWebRequestService" );
		instance.sessionStorage                   = instance.wirebox.getInstance( "sessionStorage" );
		instance.siteService                      = instance.wirebox.getInstance( "siteService" );
		instance.sitetreeService                  = instance.wirebox.getInstance( "sitetreeService" );
		instance.stickerForPreside                = instance.wirebox.getInstance( "stickerForPreside" );
		instance.tenancyService                   = instance.wirebox.getInstance( "tenancyService" );
		instance.websiteLoginService              = instance.wirebox.getInstance( "websiteLoginService" );
		instance.websitePermissionService         = instance.wirebox.getInstance( "websitePermissionService" );
	}

	/**
	* Get original controller
	*/
	function getController(){
		return instance.controller;
	}


// URL related
	public void function setSite( required struct site ) {
		getModel( "tenancyService" ).setTenantId( tenant="site", id=( site.id ?: "" ) );
		getRequestContext().setValue(
			  name    = "_site"
			, value   =  arguments.site
			, private =  true
		);
	}

	public void function autoSetSiteByHost() {
		setSite( getModel( "siteService" ).matchSite( this.getServerName(), this.getCurrentPresideUrlPath() ) );
	}

	public struct function getSite() {
		var site = getRequestContext().getValue( name="_site", private=true, defaultValue={} );

		if ( IsStruct( site ) ) {
			return site;
		}

		return {};
	}

	public string function getSiteUrl( string siteId="", boolean includePath=true, boolean includeLanguageSlug=true ) {
		var prc       = getRequestContext().getCollection( private=true );
		var fetchSite = ( prc._forceDomainLookup ?: false ) || ( Len( Trim( arguments.siteId ) ) && arguments.siteId != getSiteId() );
		var site      = fetchSite ? getModel( "siteService" ).getSite( arguments.siteId ) : getSite();
		var protocol  = ( site.protocol ?: getProtocol() );
		var domain    = "";

		if ( overwriteDomainForBuildLink() ) {
			domain = getOverwriteDomainForBuildLink();
		} else if ( fetchSite && StructKeyExists( site, "domain" ) && site.domain != "*" ) {
			domain = site.domain;
		} else {
			domain = cgi.server_name;
		}

		var siteUrl = protocol & "://" & domain;

		prc.delete( "_forceDomainLookup" );

		if ( !listFindNoCase( "80,443", cgi.SERVER_PORT ) ) {
			siteUrl &= ":#cgi.SERVER_PORT#";
		}

		if ( arguments.includePath ) {
			siteUrl &= site.path ?: "/";
		}

		if ( arguments.includeLanguageSlug ) {
			var languageSlug = this.getLanguageSlug();
			if ( Len( Trim( languageSlug ) ) ) {
				siteUrl = ReReplace( siteUrl, "/$", "" ) & "/" & languageSlug;
			}
		}

		siteUrl = siteUrl.reReplace( "/$", "" );

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

	public string function buildLink( string siteId="", string queryString="", boolean forceDomain=false ) {
		var prc = getRequestContext().getCollection( private=true );

		if ( arguments.siteId.len() ) {
			arguments.queryString = ListPrepend( arguments.queryString, "_sid=" & arguments.siteId, "&" );
		}
		if ( arguments.forceDomain ) {
			prc._forceDomainLookup = true;
		}

		announceInterception(
			  state         = "onBuildLink"
			, interceptData = arguments
		);

		var link = prc._builtLink ?: "";
		StructDelete( prc, "_builtLink" );

		if ( not Len( Trim( link ) ) and Len( Trim( arguments.linkTo ?: "" ) ) ) {
			link = getRequestContext().buildLink( argumentCollection = arguments );
		}

		return link;
	}

	public string function getProtocol() {
		if ( getController().getSetting( "forcessl" ) ) {
			return "https";
		}
		return ( cgi.https ?: "" ) == "on" ? "https" : "http";
	}

	public string function getServerName() {
		return cgi.server_name;
	}

	public string function getBaseUrl() {
		var sitesEnabled = this.getModel( "featureService" ).isFeatureEnabled( "sites" );

		if ( sitesEnabled ) {
			return this.getSiteUrl( site="", includePath=false, includeLanguageSlug=false );
		}

		var protocol = getProtocol() & "://";
		var port     = !listFindNoCase( "80,443", cgi.SERVER_PORT ) ? ( ":" & cgi.SERVER_PORT ) : "";

		if ( overwriteDomainForBuildLink() ) {
			return protocol & getOverwriteDomainForBuildLink() & port;
		}

		var allowedDomains = getController().getSetting( "allowedDomains" );

		if ( IsArray( allowedDomains ) && allowedDomains.len() ) {
			return protocol & allowedDomains[1] & port;
		}

		return protocol & getServerName() & port;
	}

	public string function getCurrentUrl( boolean includeQueryString=true ) {
		var currentUrl  = request[ "preside.path_info"    ] ?: "";
		var qs          = request[ "preside.query_string" ] ?: "";
		var includeQs   = arguments.includeQueryString && Len( Trim( qs ) );

		return includeQs ? currentUrl & "?" & qs : currentUrl;
	}

	public void function setCurrentPresideUrlPath( required string presideUrlPath ) {
		getRequestContext().setValue( name="_presideUrlPath", private=true, value=arguments.presideUrlPath );
	}

	public string function getCurrentPresideUrlPath() {
		return getRequestContext().getValue( name="_presideUrlPath", private=true, defaultValue="/" );
	}

	public boolean function overwriteDomainForBuildLink() {
		return getRequestContext().valueExists( name="_overwriteDomainForBuildLink", private=true );
	}

	public string function getOverwriteDomainForBuildLink() {
		return getRequestContext().getValue( name="_overwriteDomainForBuildLink", defaultValue="", private=true );
	}

	public void function setOverwriteDomainForBuildLink( required string domain ) {
		if ( len( arguments.domain ) ) {
			getRequestContext().setValue( name="_overwriteDomainForBuildLink", value=arguments.domain, private=true );
		}
	}

	public void function removeOverwriteDomainForBuildLink() {
		getRequestContext().removeValue( name="_overwriteDomainForBuildLink", private=true );
	}

// REQUEST DATA
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

	public struct function getCollectionForForm(
		  string  formName                = ""
		, boolean stripPermissionedFields = true
		, string  permissionContext       = ""
		, array   permissionContextKeys   = []
		, string  fieldNamePrefix         = ""
		, string  fieldNameSuffix         = ""
		, array   suppressFields          = []
		, boolean autoTrim                = _getAutoTrimDefault()
	) {
		var formNames    = Len( Trim( arguments.formName ) ) ? [ arguments.formName ] : this.getSubmittedPresideForms();
		var formsService = getModel( "formsService" );
		var rc           = getRequestContext().getCollection();
		var collection   = {};

		for( var name in formNames ) {
			var formFields     = formsService.listFields( argumentCollection=arguments, formName=name );
			var autoTrimFields = formsService.listAutoTrimFields( argumentCollection=arguments, formName=name );

			for( var field in formFields ){
				var fieldName = arguments.fieldNamePrefix & field & arguments.fieldNameSuffix;
				if ( ( arguments.autoTrim && !autoTrimFields.disabled.find( field ) ) || autoTrimFields.enabled.find( field ) ) {
					collection[ field ] = trim( rc[ fieldName ] ?: "" );
				} else {
					collection[ field ] = ( rc[ fieldName ] ?: "" );
				}
			}
		}

		return collection;
	}

	public array function getSubmittedPresideForms() {
		var rc = getRequestContext().getCollection();

		return ListToArray( Trim( rc[ "$presideform" ] ?: "" ) );
	}

// Admin specific
	public string function buildAdminLink(
		  string linkTo          = ""
		, string queryString     = ""
		, string siteId          = this.getSiteId()
		, string operationSource = ""
	) {
		if ( Len( Trim( arguments.operationSource ) ) ) {
			arguments.queryString = ListAppend( arguments.queryString, "_psource=" & arguments.operationSource, "&" );
		}

		if ( StructKeyExists( arguments, "objectName" ) ) {
			var args = {
				  objectName = arguments.objectName
				, recordId   = arguments.recordId  ?: ""
				, operation  = arguments.operation ?: ""
				, args       = arguments.args      ?: {}
			};

			args.args.append( arguments );

			return getModel( "adminObjectLinkBuilderService" ).buildLink( argumentCollection=args );
		}

		arguments.linkTo = ListAppend( "admin", arguments.linkTo, "." );

		if ( isActionRequest( arguments.linkTo ) && this.getModel( "featureService" ).isFeatureEnabled( "adminCsrfProtection" ) ) {
			arguments.queryString = ListPrepend( arguments.queryString, "csrfToken=" & this.getCsrfToken(), "&" );
		}

		return buildLink( argumentCollection = arguments );
	}

	public string function getAdminPath() {
		var path = getController().getSetting( "preside_admin_path" );

		return Len( Trim( path ) ) ? "/#path#/" : "/";
	}

	public boolean function isAdminRequest() {
		var currentUrl = getCurrentUrl();
		var adminPath  = getAdminPath();

		return currentUrl.left( adminPath.len() ) == adminPath;
	}

	public void function setIsDataManagerRequest() {
		getRequestContext().setValue(
			  name    = "_isDataManagerRequest"
			, value   = true
			, private = true
		);
	}

	public boolean function isDataManagerRequest() {
		var isDmHandler = getRequestContext().getCurrentEvent().reFindNoCase( "^admin\.datamanager\." );
		var isDmRequest = getRequestContext().getValue(
			  name         = "_isDataManagerRequest"
			, defaultValue = false
			, private      = true
		);

		return isDmHandler || isDmRequest;
	}

	public boolean function isAdminUser() {
		var loginSvc = getModel( "loginService" );

		return loginSvc.isLoggedIn();
	}

	public boolean function showNonLiveContent() {
		try {
			return request._showNonLiveContent;
		} catch( any e ) {
			if ( this.isAdminRequest() ) {
				request._showNonLiveContent = true;
			} else {
				request._showNonLiveContent = getModel( "loginService" ).isShowNonLiveEnabled();
			}

			return request._showNonLiveContent;
		}
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

		event.setHTTPHeader( statusCode="401" );
		event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
		event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

		content reset=true type="text/html";header statusCode="401";WriteOutput( getModel( "presideRenderer" ).renderLayout() );abort;
	}

	public void function audit( userId=getAdminUserId() ) {
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

	public void function initializeDatamanagerPage(
		  required string objectName
		,          string recordId   = ""
	) {
		var args = StructCopy( arguments );

		args.append({
			  eventArguments = {}
			, action         = "__custom"
		}, false );

		getController().runEvent(
			  event          = "admin.datamanager._loadCommonVariables"
			, private        = true
			, prePostExempt  = true
			, eventArguments = args
		);

		getController().runEvent(
			  event          = "admin.datamanager._loadCommonBreadCrumbs"
			, private        = true
			, prePostExempt  = true
			, eventArguments = args
		);

		setIsDataManagerRequest();
	}

	public void function doAdminSsoLogin(
		  required string  loginId
		, required struct  userData
		,          boolean rememberLogin        = false
		,          numeric rememberExpiryInDays = 90
		,          string  postLoginUrl         = getRequestContext().getValue( "postLoginUrl", "" )
	) {
		var loginService = getModel( "loginService" );
		var event        = getRequestContext();
		var rc           = event.getCollection();

		loginService.getOrCreateUser(
			  loginId = arguments.loginId
			, data    = arguments.userData
		);
		loginService.login(
			  loginId              = arguments.loginId
			, password             = ""
			, rememberLogin        = arguments.rememberLogin
			, rememberExpiryInDays = arguments.rememberExpiryInDays
			, skipPasswordCheck    = true
		);

		rc.postLoginUrl = arguments.postLoginUrl;

		postAdminLogin();
	}

	public void function postAdminLogin() {
		var user         = getAdminUserDetails();
		var event        = getRequestContext();
		var rc           = event.getCollection();
		var postLoginUrl = rc.postLoginUrl ?: "";

		if ( Len( Trim( user.user_language ?: "" ) ) ) {
			getModel( "i18n" ).setFwLocale( Trim( user.user_language ) );
		}

		announceInterception( "onAdminLoginSuccess" );

		if ( getModel( "loginService" ).twoFactorAuthenticationRequired( ipAddress = getClientIp(), userAgent = getUserAgent() ) ) {
			getController().relocate( url=buildAdminLink( linkto="login.twoStep" ), persistStruct={ postLoginUrl = postLoginUrl } );
		}

		if ( Len( Trim( postLoginUrl ) ) ) {
			var ss           = getModel( "sessionStorage" );
			var unsavedData  = ss.getVar( "_unsavedFormData", {} );

			ss.deleteVar( "_unsavedFormData", {} );

			postLoginUrl = ReReplace( Trim( postLoginUrl ), "^(https?://.*?)//", "\1/" );

			getController().relocate( url=postLoginUrl, persistStruct=unsavedData );
		} else {
			getController().runEvent( event="admin.login._redirectToDefaultAdminEvent", private=true, prePostExempt=true );
		}
	}

	public string function getAdminOperationSource( string defaultValue="" ) {
		return getModel( "sessionStorage" ).getVar( "_adminOperationSource", arguments.defaultValue );
	}
	public string function setAdminOperationSource( required string source ) {
		getModel( "sessionStorage" ).setVar( "_adminOperationSource", arguments.source );
	}

// Sticker
	public any function include() {
		return getModel( "StickerForPreside" ).include( argumentCollection = arguments );
	}

	public any function includeData() {
		return getModel( "StickerForPreside" ).includeData( argumentCollection = arguments );
	}

	public any function includeUrl() {
		return getModel( "StickerForPreside" ).includeUrl( argumentCollection = arguments );
	}

	public boolean function isWebUserImpersonated() {
		return getModel( "websiteLoginService" ).isImpersonated();
	}

	public string function renderIncludes( string type, string group="default" ) {
		var rendered      = getModel( "StickerForPreside" ).renderIncludes( argumentCollection = arguments );

		if ( !StructKeyExists( arguments, "type" ) || arguments.type == "js" ) {
			var inlineJs = getRequestContext().getValue( name="__presideInlineJs", defaultValue={}, private=true );
			var stack    = inlineJs[ arguments.group ] ?: [];

			rendered &= ArrayToList( stack, Chr(10) );

			inlineJs[ arguments.group ] = [];

			getRequestContext().setValue( name="__presideInlineJs", value=inlineJs, private=true );
		}

		return rendered;
	}

	public void function includeInlineJs( required string js, string group="default" ) {
		var inlineJs = getRequestContext().getValue( name="__presideInlineJs", defaultValue={}, private=true );

		inlineJs[ arguments.group ] = inlineJs[ arguments.group ] ?: [];
		inlineJs[ arguments.group ].append( "<script type=""text/javascript"">" & Chr(10) & arguments.js & Chr(10) & "</script>" );

		getRequestContext().setValue( name="__presideInlineJs", value=inlineJs, private=true );
	}

// Query caching
	public boolean function getUseQueryCache() {
		var event = getRequestContext();
		var useCache = event.getValue( name="__presideQueryCacheDefault", private=true, defaultValue="" );

		if ( !IsBoolean( useCache ) ) {
			useCache = getController().getSetting( "useQueryCacheDefault" );
			useCache = IsBoolean( useCache ) && useCache;

			setUseQueryCache( useCache );
		}

		return useCache;
	}
	public void function setUseQueryCache( required boolean useQueryCache ) {
		getRequestContext().setValue( name="__presideQueryCacheDefault", private=true, value=arguments.useQueryCache );
	}

// private helpers
	private boolean function _getAutoTrimDefault() {
		var context = isAdminRequest() ? "admin" : "frontend";
		var autoTrimDefault = getController().getSetting( "autoTrimFormSubmissions.#context#" );

		return IsBoolean( autoTrimDefault ) && autoTrimDefault;
	}

	public any function _getSticker() {
		return getModel( "StickerForPreside" );
	}

	public any function getModel( required string beanName ) {
		if ( StructKeyExists( instance, arguments.beanName ) ) {
			return instance[ arguments.beanName ];
		}

		return instance.wireBox.getInstance( arguments.beanName );
	}

	public any function announceInterception( required string state, struct interceptData={} ) {
		return getController().getInterceptorService().processState( argumentCollection=arguments );
	}

// security helpers
	public string function getCsrfToken() {
		return getModel( "csrfProtectionService" ).generateToken( argumentCollection = arguments );
	}

	public boolean function validateCsrfToken() {
		return getModel( "csrfProtectionService" ).validateToken( argumentCollection = arguments );
	}

	public boolean function isActionRequest( string ev=getRequestContext().getCurrentEvent() ) {
		var currentEvent = LCase( arguments.ev );

		if ( ReFind( "^admin\.ajaxProxy\..*?", currentEvent ) ) {
			currentEvent = "admin." & LCase( event.getValue( "action", "" ) );
		}

		return ReFind( "^admin\..*?action$", currentEvent );
	}

	public boolean function isStatelessRequest() {
		var appSettings = GetApplicationSettings();

		return IsBoolean( appSettings.statelessRequest ?: "" ) && appSettings.statelessRequest;
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

		this.setHTTPHeader( name="X-Frame-Options", value=arguments.value, overwrite=true );
	}

// FRONT END, dealing with current page
	public void function initializePresideSiteteePage (
		  string  slug
		, string  pageId
		, string  systemPage
		, string  subaction
	) {
		var sitetreeSvc = getModel( "sitetreeService" );
		var rc          = getRequestContext().getCollection();
		var prc         = getRequestContext().getCollection( private = true );
		var allowDrafts = this.showNonLiveContent();
		var getLatest   = allowDrafts;
		var page        = "";
		var parentPages = "";
		var getPageArgs = {};
		var isActive    = function( required boolean active, required string embargo_date, required string expiry_date ) {
			return arguments.active && ( !IsDate( arguments.embargo_date ) || Now() >= arguments.embargo_date ) && ( !IsDate( arguments.expiry_date ) || Now() <= arguments.expiry_date );
		}

		if ( ( arguments.slug ?: "/" ) == "/" && !Len( Trim( arguments.pageId ?: "" ) ) && !Len( Trim( arguments.systemPage ?: "" ) ) ) {
			page = sitetreeSvc.getSiteHomepage( getLatest=getLatest, allowDrafts=allowDrafts );
			parentPages = QueryNew( page.columnlist );
		} else {
			if ( Len( Trim( arguments.pageId ?: "" ) ) ) {
				getPageArgs.id = arguments.pageId;
			} else if ( Len( Trim( arguments.systemPage ?: "" ) ) ) {
				getPageArgs.systemPage = arguments.systemPage;
			} else {
				getPageArgs.slug = arguments.slug;
			}
			page = sitetreeSvc.getPage( argumentCollection=getPageArgs, getLatest=getLatest, allowDrafts=allowDrafts );
		}

		if ( !page.recordCount ) {
			return;
		}

		for( var p in page ){ page = p; break; } // quick query row to struct hack

		StructAppend( page, sitetreeSvc.getExtendedPageProperties( id=page.id, pageType=page.page_type, getLatest=getLatest, allowDrafts=allowDrafts ) );
		var ancestors = sitetreeSvc.getAncestors( id = page.id );
		page.ancestors = [];

		page.ancestorList = ancestors.recordCount ? ValueList( ancestors.id ) : "";
		page.permissionContext = [ page.id ];
		for( var i=ListLen( page.ancestorList ); i > 0; i-- ){
			page.permissionContext.append( ListGetAt( page.ancestorList, i ) );
		}

		clearBreadCrumbs();
		for( var ancestor in ancestors ) {
			addBreadCrumb( title=ancestor.title, link=buildLink( page=ancestor.id ), menuTitle=ancestor.navigation_title ?: "" );
			page.ancestors.append( ancestor );
		}
		addBreadCrumb( title=page.title, link=buildLink( page=page.id ), menuTitle=page.navigation_title ?: "" );

		page.isInDateAndActive = isActive( argumentCollection = page );
		if ( page.isInDateAndActive ) {
			for( var ancestor in page.ancestors ) {
				page.isInDateAndActive = isActive( argumentCollection = ancestor );
				if ( !page.isInDateAndActive ) {
					break;
				}
			}
		}

		page[ "slug" ] = page._hierarchy_slug;
		StructDelete( page, "_hierarchy_slug" );

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
				addBreadCrumb( title=ancestor.title, link=buildLink( page=ancestor.id ), menuTitle=ancestor.navigation_title ?: "" );
				page.ancestors.append( ancestor );
			}

			for( var p in arguments.parentPage ){
				addBreadCrumb( title=p.title, link=buildLink( page=p.id ), menuTitle=p.navigation_title ?: "" );
				page.ancestors.append( p );
			}
		}

		addBreadCrumb( title=page.title ?: "", link=getCurrentUrl(), menuTitle=page.navigation_title ?: "" );

		prc.presidePage = page;

		announceInterception( "postInitializeDummyPresideSiteTreePage" );
	}

	public void function checkPageAccess() {
		if ( !getCurrentPageId().len() ) {
			return;
		}

		var websiteLoginService = getModel( "websiteLoginService" );
		var accessRules         = getPageAccessRules();

		if ( accessRules.access_restriction == "full" || accessRules.access_restriction == "partial" ){
			var fullLoginRequired = IsBoolean( accessRules.full_login_required ) && accessRules.full_login_required;
			var loggedIn          = websiteLoginService.isLoggedIn() && (!fullLoginRequired || !websiteLoginService.isAutoLoggedIn() );

			if ( Len( Trim( accessRules.access_condition ) ) ) {
				var conditionIsTrue = getModel( "rulesEngineWebRequestService" ).evaluateCondition( accessRules.access_condition );

				if ( !conditionIsTrue ) {
					if ( !loggedIn ) {
						accessRules.access_restriction == "full" ? accessDenied( reason="LOGIN_REQUIRED" ) : this.setPartiallyRestricted( true );
					} else {
						accessRules.access_restriction == "full" ? accessDenied( reason="INSUFFICIENT_PRIVILEGES" ) : this.setPartiallyRestricted( true );
					}
				}
			} else {
				if ( !loggedIn ) {
					accessRules.access_restriction == "full" ? accessDenied( reason="LOGIN_REQUIRED" ) : this.setPartiallyRestricted( true );
				}

				hasPermission = getModel( "websitePermissionService" ).hasPermission(
					  permissionKey       = "pages.access"
					, context             = "page"
					, contextKeys         = [ accessRules.access_defining_page ]
					, forceGrantByDefault = IsBoolean( accessRules.grantaccess_to_all_logged_in_users ) && accessRules.grantaccess_to_all_logged_in_users
				);

				if ( !hasPermission ) {
					accessRules.access_restriction == "full" ? accessDenied( reason="INSUFFICIENT_PRIVILEGES" ) : this.setPartiallyRestricted( true );
				}
			}
		}
	}

	public struct function getPageAccessRules() {
		var prc = getRequestContext().getCollection( private = true );

		if ( !StructKeyExists( prc, "pageAccessRules" ) ) {
			prc.pageAccessRules = getModel( "sitetreeService" ).getAccessRestrictionRulesForPage( getCurrentPageId() );
		}

		return prc.pageAccessRules;
	}

	public void function setPartiallyRestricted( required boolean isRestricted ) {
		var prc = getRequestContext().getCollection( private = true );

		prc.isPartiallyRestricted = arguments.isRestricted;
	}

	public boolean function isPagePartiallyRestricted() {
		var prc = getRequestContext().getCollection( private = true );

		return IsBoolean( prc.isPartiallyRestricted ?: "" ) && prc.isPartiallyRestricted;
	}

	public void function preventPageCache() {
		header name="cache-control" value="no-cache, no-store";
		header name="expires"       value="Fri, 20 Nov 2015 00:00:00 GMT";
	}

	public boolean function canPageBeCached() {
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
				for( var node in cascadeSearch ){
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

	public void function addBreadCrumb( required string title, required string link, string menuTitle="" ) {
		var crumbs = getBreadCrumbs();

		ArrayAppend( crumbs, {
			  title     = arguments.title
			, link      = arguments.link
			, menuTitle = arguments.menuTitle.len() ? arguments.menuTitle : arguments.title
		} );

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

		if ( !StructKeyExists( prc, "_presideCmsEditPageLink" ) ) {
			setEditPageLink( buildAdminLink( linkTo='sitetree.editPage', queryString='id=#getCurrentPageId()#' ) );
		}

		return prc._presideCmsEditPageLink;
	}
	public void function setEditPageLink( required string editPageLink ) {
		getRequestContext().setValue( name="_presideCmsEditPageLink", value=arguments.editPageLink, private=true );
	}

// FRONT END - Multilingual helpers
	public string function getLanguage() {
		return getRequestContext().getValue( name="_language", defaultValue="", private=true );
	}
	public void function setLanguage( required string language ) {
		getRequestContext().setValue( name="_language", value=arguments.language, private=true );
		getModel( "multilingualPresideObjectService" ).persistUserLanguage( arguments.language );
	}

	public string function getLanguageSlug() {
		return getRequestContext().getValue( name="_languageSlug", defaultValue="", private=true );
	}
	public void function setLanguageSlug( required string languageSlug ) {
		getRequestContext().setValue( name="_languageSlug", value=arguments.languageSlug, private=true );
	}

	public string function getLanguageCode() {
		return getRequestContext().getValue( name="_languageCode", defaultValue="en", private=true );
	}
	public void function setLanguageCode( required string languageCode ) {
		getRequestContext().setValue( name="_languageCode", value=arguments.languageCode, private=true );
	}

// HTTP Header helpers
	public string function getClientIp() {
		var httpHeaders = getHttpRequestData().headers;
		var clientIp    = httpHeaders[ "x-real-ip" ] ?: ( httpHeader[ "x-forwarded-for"] ?: cgi.remote_addr );

		return Trim( ListFirst( clientIp ) );
	}

	public string function getUserAgent() {
		return cgi.http_user_agent;
	}

	function setHTTPHeader( string statusCode, string statusText="", string name, string value="", boolean overwrite=false ){
		if ( StructKeyExists( arguments, "statusCode" ) ) {
			getPageContext().getResponse().setStatus( javaCast( "int", arguments.statusCode ), javaCast( "string", arguments.statusText ) );
		} else if ( StructKeyExists( arguments, "name" ) ) {
			if ( arguments.overwrite ) {
				getPageContext().getResponse().setHeader( javaCast( "string", arguments.name ), javaCast( "string", arguments.value ) );
			} else {
				getPageContext().getResponse().addHeader( javaCast( "string", arguments.name ), javaCast( "string", arguments.value ) );
			}
		} else {
			throw( message="Invalid header arguments",
				  detail="Pass in either a statusCode or name argument",
				  type="RequestContext.InvalidHTTPHeaderParameters" );
		}

		return this;
	}

// CACHING HELPERS
	public boolean function cachePage( boolean cache ) {
		var event = getRequestContext();
		var prc   = event.getCollection( private=true );

		if ( StructKeyExists( arguments, "cache" ) ) {
			prc._cachePage = arguments.cache;
			return arguments.cache;
		}

		return getModel( "featureService" ).isFeatureEnabled( "fullPageCaching" )
		    && !event.valueExists( "fwreinit" )
		    && !this.isAdminRequest()
		    && !this.isAdminUser()
		    && event.getHTTPMethod() == "GET"
		    && !this.getCurrentUrl().reFindNoCase( "^/asset/" )
		    && !( IsBoolean( prc._cachePage ?: "" ) && !prc._cachePage );
	}

	public void function setNonCacheableRequestData() {
		var event           = getRequestContext();
		var rc              = event.getCollection( private=false );
		var prc             = event.getCollection( private=true  );
		var flashCache      = getController().getRequestService().getFlashScope().getFlash();
		var uncacheableKeys = StructKeyArray( flashCache );

		ArrayAppend( uncacheableKeys, StructKeyArray( rc ), true );

		prc._fullPageCachingUncacheableKeys = ListToArray( LCase( ArrayToList( uncacheableKeys ) ) );
	}

	private boolean function isCacheable( required any value ) {
		return IsSimpleValue( arguments.value ) || IsArray( arguments.value ) || IsStruct( arguments.value ) || IsQuery( arguments.value );
	}

	public struct function getCacheableRequestData() {
		var event            = getRequestContext();
		var rc               = event.getCollection( private=false );
		var prc              = event.getCollection( private=true  );
		var unCacheableKeys  = prc._fullPageCachingUncacheableKeys ?: [];
		var fpcSettings      = getController().getSetting( name="fullpagecaching", defaultValue={} );
		var limitData        = IsBoolean( fpcSettings.limitCacheData ?: "" ) && fpcSettings.limitCacheData;
		var cacheableVars    = { prc={}, rc={} };

		if ( limitData ) {
			var limitRc  = fpcSettings.limitCacheDataKeys.rc  ?: [];
			var limitPrc = fpcSettings.limitCacheDataKeys.prc ?: [];
		}

		if ( !limitData || limitRc.len() ) {
			for( var key in rc ) {
				if ( !isNull( rc[ key ] ) && (!limitData || ArrayFind( limitRc, key ) ) && !ArrayFind( unCacheableKeys, LCase( key ) ) && isCacheable( rc[ key ] ) ) {
					cacheableVars.rc[ key ] = Duplicate( rc[ key ] );
				}
			}
		}
		if ( !limitData || limitPrc.len() ) {
			for( var key in prc ) {
				if ( !isNull( prc[ key ] ) && ( !limitData || ArrayFind( limitPrc, key ) ) && isCacheable( prc[ key ] ) ) {
					cacheableVars.prc[ key ] = Duplicate( prc[ key ] );
				}
			}
		}

		return cacheableVars;
	}

	public void function restoreCachedData( required struct cachedData ) {
		var event = getRequestContext();
		var rc    = event.getCollection( private=false );
		var prc   = event.getCollection( private=true  );

		rc.append( cachedData.rc ?: {}, false );
		prc.append( cachedData.prc ?: {}, false );

		getController().getRequestService().getFlashScope().inflateFlash();
	}

	public void function setPageCacheTimeout( required numeric timeoutInSeconds ) {
		var event = getRequestContext();
		var prc   = event.getCollection( private=true );

		prc._pageCacheTimeout = arguments.timeoutInSeconds;
	}

	public any function getPageCacheTimeout() {
		var event = getRequestContext();
		var prc   = event.getCollection( private=true );

		return prc._pageCacheTimeout ?: NullValue();
	}

// status codes
	public void function notFound() {
		announceInterception( "onNotFound" );
		getController().runEvent( "general.notFound" );
		content reset=true type="text/html";header statusCode="404";

		var contentOutput = getModel( "presideRenderer" ).renderLayout();

		contentOutput = getModel( "delayedStickerRendererService" ).renderDelayedStickerIncludes( contentOutput );
		contentOutput = getModel( "delayedViewletRendererService" ).renderDelayedViewlets(        contentOutput );
		writeOutput( contentOutput );
		abort;
	}

	public void function accessDenied( required string reason ) {
		announceInterception( "onAccessDenied" , arguments );
		getController().runEvent( event="general.accessDenied", eventArguments={ args=arguments }, private=true );

		var contentOutput = getModel( "presideRenderer" ).renderLayout();

		contentOutput = getModel( "delayedStickerRendererService" ).renderDelayedStickerIncludes( contentOutput );
		contentOutput = getModel( "delayedViewletRendererService" ).renderDelayedViewlets(        contentOutput );
		writeOutput( contentOutput );
		abort;
	}

// REST framework
	public any function getRestRequest() {
		var prc = getRequestContext().getCollection( private = true );
		return prc._restRequest ?: NullValue();
	}
	public void function setRestRequest( required any restRequest ) {
		var prc = getRequestContext().getCollection( private = true );
		prc._restRequest = arguments.restRequest;
	}
	public string function getRestRequestUser() {
		var restRequest = getRestRequest();
		if ( !IsNull( restRequest ) ) {
			return restRequest.getUser();
		}

		return "";
	}

	public any function getRestResponse() {
		var prc = getRequestContext().getCollection( private = true );
		return prc._restResponse ?: NullValue();
	}
	public void function setRestResponse( required any restResponse ) {
		var prc = getRequestContext().getCollection( private = true );
		prc._restResponse = arguments.restResponse;
	}


// private helpers
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