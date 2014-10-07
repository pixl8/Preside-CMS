component output="false" extends="preside.system.base.AdminHandler" {

	property name="siteTreeService"          inject="siteTreeService";
	property name="applicationPagesService"  inject="applicationPagesService";
	property name="formsService"             inject="formsService";
	property name="pageTypesService"         inject="pageTypesService";
	property name="validationEngine"         inject="validationEngine";
	property name="websitePermissionService" inject="websitePermissionService";
	property name="messageBox"               inject="coldbox:plugin:messageBox";

	public void function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !hasCmsPermission( "sitetree.navigate" ) ) {
			event.adminAccessDenied();
		}

		prc.homepage = siteTreeService.getSiteHomepage();

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sitetree" )
			, link  = event.buildAdminLink( linkTo="sitetree" )
		);
	}

	public void function index( event, rc, prc ) output=false {
		prc.activeTree          = siteTreeService.getTree( trash = false, format="nestedArray", selectFields=[ "id", "parent_page", "title", "slug", "active", "page_type", "datecreated", "datemodified", "_hierarchy_slug as full_slug", "trashed", "access_restriction" ] );
		prc.applicationPageTree = applicationPagesService.getTree();
	}

	public void function trash( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="viewtrash" );
		prc.treeTrash = siteTreeService.getTree( trash = true, format="nestedArray", selectFields=[ "id", "parent_page", "title", "slug", "active", "page_type", "datecreated", "datemodified", "_hierarchy_slug as full_slug", "trashed", "access_restriction" ] );
	}

	public void function addPage( event, rc, prc ) output=false {
		var parentPageId = rc.parent_page ?: "";
		var pageType     = rc.page_type ?: "";

		_checkPermissions( argumentCollection=arguments, key="add", pageId=parentPageId );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.addPage.title" )
			, link  = ""
		);

		prc.parentPage = siteTreeService.getPage(
			  id              = parentPageId
			, includeInactive = true
			, selectFields    = [ "title" ]
		);
		if ( not prc.parentPage.recordCount ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
			setNextEvent( url = event.buildAdminLink( linkTo="sitetree" ) );
		}

		if ( !pageTypesService.pageTypeExists( pageType ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( pageType );

		prc.mainFormName  = "preside-objects.page.add";
		prc.mergeFormName = _getPageTypeFormName( pageType, "add" );
	}

	public void function addPageAction( event, rc, prc ) output=false {
		var parent            = rc.parent_page ?: "";
		var pageType          = rc.page_type   ?: "";
		var formName          = "preside-objects.page.add";
		var formData          = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";

		_checkPermissions( argumentCollection=arguments, key="add", pageId=parent );

		if ( !pageTypesService.pageTypeExists( pageType ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( pageType );
		var mergeFormName = _getPageTypeFormName( pageType, "add" );
		if ( Len( Trim( mergeFormName ) ) ) {
			formName = formsService.getMergedFormName( formName, mergeFormName );
		}

		formData             = event.getCollectionForForm( formName );
		formData.parent_page = parent;
		formData.page_type   = rc.page_type;

		validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.addPage" ), persistStruct=persist );
		}

		newId = siteTreeService.addPage( argumentCollection = formData );

		websitePermissionService.syncContextPermissions(
			  context       = "page"
			, contextKey    = newId
			, permissionKey = "pages.access"
			, grantBenefits = ListToArray( rc.grant_access_to_benefits ?: "" )
			, denyBenefits  = ListToArray( rc.deny_access_to_benefits  ?: "" )
			, grantUsers    = ListToArray( rc.grant_access_to_users    ?: "" )
			, denyUsers     = ListToArray( rc.deny_access_to_users     ?: "" )
		);


		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageAdded.confirmation" ) );
		if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
			persist = {
				  _addanother = 1
				, active      = formData.active ?: 0
			}

			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#parent#&page_type=#rc.page_type#" ), persistStruct=persist );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#newId#" ) );
		}
	}

	public void function editPage( event, rc, prc ) output=false {
		var pageId           = rc.id               ?: "";
		var validationResult = rc.validationResult ?: "";
		var version          = Val ( rc.version    ?: "" );
		var pageType         = "";

		_checkPermissions( argumentCollection=arguments, key="edit", pageId=pageId );
		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments, allowVersions=true );

		if ( !pageTypesService.pageTypeExists( prc.page.page_type ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( prc.page.page_type );

		prc.mainFormName  = "preside-objects.page.edit";
		prc.mergeFormName = _getPageTypeFormName( pageType, "edit" )

		prc.page = QueryRowToStruct( prc.page );
		var savedData = getPresideObject( pageType.getPresideObject() ).selectData( filter={ page = pageId }, fromVersionTable=( version > 0 ), specificVersion=version  );
		StructAppend( prc.page, QueryRowToStruct( savedData ) );

		var contextualAccessPerms = websitePermissionService.getContextualPermissions(
			  context       = "page"
			, contextKey    = pageId
			, permissionKey = "pages.access"
		);
		prc.page.grant_access_to_benefits = ArrayToList( contextualAccessPerms.benefit.grant );
		prc.page.deny_access_to_benefits  = ArrayToList( contextualAccessPerms.benefit.deny );
		prc.page.grant_access_to_users    = ArrayToList( contextualAccessPerms.user.grant );
		prc.page.deny_access_to_users     = ArrayToList( contextualAccessPerms.user.deny );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.editPage.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function editPageAction( event, rc, prc ) output=false {
		var pageId            = event.getValue( "id", "" );
		var validationRuleset = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";
		var formName          = "preside-objects.page.edit";
		var formData          = "";
		var page              = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="edit", pageId=pageId );

		if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( page.page_type );
		var mergeFormName = _getPageTypeFormName( pageType, "edit" )
		if ( Len( Trim( mergeFormName ) ) ) {
			formName = formsService.getMergedFormName( formName, mergeFormName );
		}

		formData         = event.getCollectionForForm( formName );
		formData.id      = pageId;
		validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ), persistStruct=persist );
		}

		try {
			siteTreeService.editPage( argumentCollection = formData );
		} catch( "SiteTreeService.BadParent" e ) {
			validationResult.addError( fieldname="parent_page", message="cms:sitetree.validation.badparent.error" );

			getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ), persistStruct=persist );
		}

		websitePermissionService.syncContextPermissions(
			  context       = "page"
			, contextKey    = pageId
			, permissionKey = "pages.access"
			, grantBenefits = ListToArray( rc.grant_access_to_benefits ?: "" )
			, denyBenefits  = ListToArray( rc.deny_access_to_benefits  ?: "" )
			, grantUsers    = ListToArray( rc.grant_access_to_users    ?: "" )
			, denyUsers     = ListToArray( rc.deny_access_to_users     ?: "" )
		);

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageEdited.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#pageId#" ) );
	}

	public void function editApplicationPage( event, rc, prc ) output=false {
		var pageId           = rc.id               ?: "";
		var validationResult = rc.validationResult ?: "";

		// _checkPermissions( argumentCollection=arguments, key="edit", pageId=pageId );

		if ( !applicationPagesService.pageExists( pageId ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.application.page.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		prc.configFormName = applicationPagesService.getPageConfigFormName( pageId );
		prc.pageConfig     = applicationPagesService.getPageConfiguration( pageId );

		prc.applicationPageTitle = translateResource( "application-pages:#pageId#.name" );
		prc.applicationPageIcon  = translateResource( "application-pages:#pageId#.icon" );

		prc.pageIcon   = ReReplace( prc.applicationPageIcon, "$fa\-", "" );
		prc.pageTitle  = translateResource( uri="cms:sitetree.editPage.title", data=[ prc.applicationPageTitle ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.editPage.crumb", data=[ prc.applicationPageTitle ] )
			, link  = ""
		);
	}

	public void function trashPageAction( event, rc, prc ) output=false {
		var pageId  = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="trash", pageId=pageId );

		if ( pageId eq prc.homepage.id ) {
			getPlugin( "MessageBox" ).error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		var page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		siteTreeService.trashPage( pageId );

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageTrashed.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#page.parent_page#"  ) );
	}

	public void function deletePageAction( event, rc, prc ) output=false {
		var pageId = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="delete", pageId=pageId );

		if ( pageId eq prc.homepage.id ) {
			getPlugin( "MessageBox" ).error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		_getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		siteTreeService.permanentlyDeletePage( event.getValue( "id", "" ) );

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageDeleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
	}

	public void function emptyTrashAction( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="emptytrash" );

		siteTreeService.emptyTrash();

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.trashEmptied.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
	}

	public void function restorePage( event, rc, prc ) output=false {
		var pageId = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="restore", pageId=pageId );

		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		prc.page = QueryRowToStruct( prc.page );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.restorePage.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function restorePageAction( event, rc, prc ) output=false {
		var pageId            = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="restore", pageId=pageId );
		_getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		var formName          = "preside-objects.page.restore";
		var formData          = event.getCollectionForForm( formName );
		var validationResult  = "";
		var newId             = "";
		var persist           = "";

		validationResult = validateForm( formName = formName, formData = formData );

		if ( not validationResult.validated() ) {
			getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.restorePage", querystring="id=#pageId#" ), persistStruct=persist );
		}

		siteTreeService.restorePage(
			  id          = pageId
			, parent_page = event.getValue( "parent_page", "" )
			, slug        = event.getValue( "slug", "" )
			, active      = event.getValue( "active", "" )
		);

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageRestored.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", queryString="selected=#pageId#" ) );
	}

	public void function reorderChildren( event, rc, prc ) output=false {
		var pageId = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="sort", pageId=pageId );

		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		prc.childPages = siteTreeService.getDescendants(
			  id       = pageId
			, depth        = 1
			, selectFields = [ "id", "title" ]
		);

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.reorderChildren.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function reorderChildrenAction( event, rc, prc ) output=false {
		var pageId  = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="sort", pageId=pageId );

		var sortedPages = ListToArray( event.getValue( "ordered", "" ) );
		var i = 0;

		for( i=1; i lte ArrayLen( sortedPages ); i++ ){
			siteTreeService.editPage(
				  id     = sortedPages[i]
				, sort_order = i
			);
		}

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.childrenReordered.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", queryString="selected=#pageId#" ) );
	}

	public void function editPagePermissions( event, rc, prc ) output=false {
		var pageId   = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId );

		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		prc.inheritedPermissionContext = _getPagePermissionContext( argumentCollection=arguments, includePageId=false );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.editPagePermissions.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function editPagePermissionsAction( event, rc, prc ) output=false {
		var pageId = event.getValue( "id", "" );
		var page   = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId );

		if ( runEvent( event="admin.Permissions.saveContextPermsAction", private=true ) ) {
			messageBox.info( translateResource( uri="cms:sitetree.cmsPermsSaved.confirmation", data=[ page.title ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.index", queryString="selected=#pageId#" ) );
		}

		messageBox.error( translateResource( uri="cms:sitetree.cmsPermsSaved.error", data=[ page.title ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id=#pageId#" ) );
	}

	public void function pageHistory( event, rc, prc ) output=false {
		var pageId   = event.getValue( "id", "" );
		var pageType = "";

		_checkPermissions( argumentCollection=arguments, key="viewversions", pageId=pageId );
		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments );


		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.pageHistory.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function pageTypeDialog( event, rc, prc ) output=false {
		var parentPage = sitetreeService.getPage( id=rc.parentPage, selectFields=[ "page_type" ] );

		if ( parentPage.recordCount ) {
			prc.pageTypes = pageTypesService.listPageTypes( allowedBeneathParent=parentPage.page_type );
		} else {
			prc.pageTypes = pageTypesService.listPageTypes();
		}

		event.setView( view="admin/sitetree/pageTypeDialog", nolayout=true );
	}

	public void function getPagesForAjaxPicker( event, rc, prc ) output=false {
		var records = siteTreeService.getPagesForAjaxSelect(
			  maxRows      = rc.maxRows      ?: 1000
			, searchQuery  = rc.q            ?: ""
			, ids          = ListToArray( rc.values ?: "" )
		);
		var preparedPages = [];

		for ( record in records ) {
			if ( IsNull( record.parent ?: ""  ) || !Len( Trim( record.parent ?: "" ) ) ) {
				record.parent = "";
			}
			if ( record.depth ) {
				record.parent = RepeatString( "&rarr;", record.depth ) & record.parent;
			}

			preparedPages.append( record );
		}

		event.renderData( type="json", data=preparedPages );
	}

	public void function getPageHistoryForAjaxDataTables( event, rc, prc ) output=false {
		var pageId = rc.id     ?: "";

		_checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId );

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = "page"
				, recordId   = pageId
				, gridFields = ( rc.gridFields ?: 'datemodified,_version_author,title' )
				, actionsView = "admin/sitetree/_historyActions"
			}
		);
	}


<!--- private helpers --->
	private void function _checkPermissions( event, rc, prc, required string key, string pageId="" ) output=false {
		var permitted = "";
		var permKey   = "sitetree." & arguments.key;

		if ( Len( Trim( arguments.pageId ) ) ) {
			permitted = hasCmsPermission( permissionKey=permKey, context="page", contextKeys=_getPagePermissionContext( argumentCollection=arguments ) );

		} else {
			permitted = hasCmsPermission( permissionKey=permKey );
		}

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

	private string function _getPageTypeFormName( required any pageType, required string addOrEdit ) output=false {
		var specificForm = addOrEdit == "add" ? pageType.getAddForm() : pageType.getEditForm();
		var defaultForm  = pageType.getDefaultForm();

		if ( formsService.formExists( specificForm ) ) {
			return specificForm;
		}
		if ( formsService.formExists( defaultForm ) ) {
			return defaultForm;
		}

		return "";
	}

	private query function _getPageAndThrowOnMissing( event, rc, prc, pageId, includeTrash=false, allowVersions=false ) output=false {
		var pageId  = arguments.pageId        ?: ( rc.id ?: "" );
		var version = arguments.allowVersions ? 0 : ( rc.version ?: 0 );
		var page    = siteTreeService.getPage(
			  id              = pageId
			, version         = Val( version )
			, includeInactive = true
			, includeTrash    = arguments.includeTrash
		);

		if ( not page.recordCount ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.page.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		return page;
	}

	private array function _getPagePermissionContext( event, rc, prc, pageId, includePageId=true ) output=false {
		var pageId   = arguments.pageId ?: ( rc.id ?: "" );
		var cacheKey = "pagePermissionContext";

		if ( prc.keyExists( cacheKey ) ) {
			return prc[ cacheKey ];
		}

		var ancestors = sitetreeService.getAncestors( id = pageId, selectFields=[ "id" ] );
		var context   = ancestors.recordCount ? ListToArray( ValueList( ancestors.id ) ) : [];
		var reversed  = [];

		if ( arguments.includePageId ) {
			context.append( pageId );
		}

		for( var i=context.len(); i>0; i-- ){
			reversed.append( context[i] );
		}

		prc[ cacheKey ] = reversed;

		return reversed;
	}
}