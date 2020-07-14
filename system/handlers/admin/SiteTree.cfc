component extends="preside.system.base.AdminHandler" {

	property name="siteTreeService"                  inject="siteTreeService";
	property name="presideObjectService"             inject="presideObjectService";
	property name="formsService"                     inject="formsService";
	property name="pageTypesService"                 inject="pageTypesService";
	property name="websitePermissionService"         inject="websitePermissionService";
	property name="dataManagerService"               inject="dataManagerService";
	property name="versioningService"                inject="versioningService";
	property name="multilingualPresideObjectService" inject="multilingualPresideObjectService";
	property name="messageBox"                       inject="messagebox@cbmessagebox";
	property name="pageCache"                        inject="cachebox:PresidePageCache";
	property name="cookieService"                    inject="cookieService";

	public void function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "sitetree" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( "sitetree.navigate" ) ) {
			event.adminAccessDenied();
		}

		prc.homepage = siteTreeService.getSiteHomepage();

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sitetree" )
			, link  = event.buildAdminLink( linkTo="sitetree" )
		);
	}

	public void function index( event, rc, prc ) {
		if ( ( rc.selected ?: "" ).len() ) {
			prc.selectedAncestors = sitetreeService.getAncestors( id=rc.selected, selectFields=[ "id" ] );
			prc.selectedAncestors = prc.selectedAncestors.recordCount ? ValueArray( prc.selectedAncestors.id ) : [];
			event.includeData( { selectedNode = rc.selected } );
		}
		prc.activeTree = siteTreeService.getTree( trash = false, format="nestedArray", maxDepth=0, selectFields=[
			  "page.id"
			, "page.parent_page"
			, "page.title"
			, "page.slug"
			, "page.main_image"
			, "page.active"
			, "page.page_type"
			, "page.datecreated"
			, "page.datemodified"
			, "page._hierarchy_slug as full_slug"
			, "page.trashed"
			, "page.access_restriction"
			, "page._version_is_draft as is_draft"
			, "page._version_has_drafts as has_drafts"
			, "Count( child_pages.id ) as child_count"
		] );

		prc.trashCount = siteTreeService.getTrashCount();
	}

	public void function ajaxChildNodes( event, rc, prc ) {
		var rendered         = "";
		var parentId         = rc.parentId ?: "";
		var parentPage       = siteTreeService.getPage( id=parentId, selectFields=[ "_hierarchy_lineage", "_hierarchy_depth", "access_restriction", "page_type" ] );
		var managedPageTypes = getManagedChildPageTypes( parentPage.page_type ).listToArray();
		var ancestors        = siteTreeService.getAncestors( id=parentId, selectFields=[ "id", "access_restriction" ] );
		var tree             = siteTreeService.getTree( trash = false, rootPageId=parentId, maxDepth=0, selectFields=[
			  "page.id"
			, "page.parent_page"
			, "page.title"
			, "page.slug"
			, "page.main_image"
			, "page.active"
			, "page.page_type"
			, "page.datecreated"
			, "page.datemodified"
			, "page.embargo_date"
			, "page.expiry_date"
			, "page._hierarchy_slug as full_slug"
			, "page.trashed"
			, "page.access_restriction"
			, "page._hierarchy_depth"
			, "page._version_is_draft as is_draft"
			, "page._version_has_drafts as has_drafts"
			, "Count( child_pages.id ) as child_count"
		] );

		var additionalNodeArgs = {
			  editPageBaseLink            = event.buildAdminLink( linkTo="sitetree.editPage"           , queryString="id={id}&child_count={child_count}" )
			, pageTypeDialogBaseLink      = event.buildAdminLink( linkTo="sitetree.pageTypeDialog"     , queryString="parentPage={id}"                   )
			, addPageBaseLink             = event.buildAdminLink( linkTo="sitetree.addPage"            , querystring="parent_page={id}&page_type={type}" )
			, trashPageBaseLink           = event.buildAdminLink( linkTo="sitetree.trashPageAction"    , queryString="id={id}"                           )
			, pageHistoryBaseLink         = event.buildAdminLink( linkTo="sitetree.pageHistory"        , queryString="id={id}"                           )
			, editPagePermissionsBaseLink = event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id={id}"                           )
			, reorderChildrenBaseLink     = event.buildAdminLink( linkTo="sitetree.reorderChildren"    , queryString="id={id}"                           )
			, previewPageBaseLink         = event.buildAdminLink( linkTo="sitetree.previewPage"        , queryString="id={id}"                           )
			, permission_context          = []
			, parent_restriction          = "inherit"
		};

		if ( ancestors.recordCount ) {
			additionalNodeArgs.permission_context = ValueArray( ancestors.id );
			additionalNodeArgs.permission_context = additionalNodeArgs.permission_context.reverse();
		}
		additionalNodeArgs.permission_context.prepend( parentId );

		if ( parentPage.access_restriction != "inherit" ) {
			additionalNodeArgs.parent_restriction = parentPage.access_restriction;
		} else {
			for( var i=ancestors.recordcount; i>0; i-- ) {
				if ( ancestors.access_restriction[i] != "inherit" ) {
					additionalNodeArgs.parent_restriction = ancestors.access_restriction[i];
					break;
				}
			}
		}

		managedChildrenBaseLink = event.buildAdminLink( linkTo="sitetree.managedChildren", queryString="parent={id}&pageType={type}" );

		for( var pageType in managedPageTypes ) {
			rendered &= renderView( view="/admin/sitetree/_managedPageTypeNode", args={
				  depth                   = parentPage._hierarchy_depth + 1
				, pagetype                = pageType
				, parentId                = parentId
				, managedChildrenBaseLink = managedChildrenBaseLink
			} );
		}

		if ( ( rc.selected ?: "" ).len() ) {
			prc.selectedAncestors = sitetreeService.getAncestors( id=rc.selected, selectFields=[ "id" ] );
			prc.selectedAncestors = prc.selectedAncestors.recordcount ? ValueArray( prc.selectedAncestors.id ) : [];
			event.includeData( { selectedPage = rc.selected } );
		}

		for( var node in tree ) {
			node.append( additionalNodeArgs );
			rendered &= renderView( view="/admin/sitetree/_node", args=node );
		}
		event.renderData( data=rendered );
	}

	public void function trash( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="viewtrash" );
		prc.treeTrash = siteTreeService.getTree( trash = true, format="nestedArray", selectFields=[ "page.id", "parent_page", "title", "slug", "active", "page_type", "datecreated", "datemodified", "_hierarchy_slug as full_slug", "trashed", "access_restriction" ] );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sitetree.trash.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="sitetree.trash" )
		);
	}

	public void function addPage( event, rc, prc ) {
		var parentPageId = rc.parent_page ?: "";
		var pageType     = rc.page_type ?: "";

		_checkPermissions( argumentCollection=arguments, key="add", pageId=parentPageId );
		prc.canPublish   = _checkPermissions( argumentCollection=arguments, key="publish", pageId=parentPageId, throwOnError=false );
		prc.canSaveDraft = _checkPermissions( argumentCollection=arguments, key="saveDraft", pageId=parentPageId, throwOnError=false );

		if ( !prc.canPublish && !prc.canSaveDraft ) {
			event.adminAccessDenied();
		}

		prc.parentPage = siteTreeService.getPage(
			  id              = parentPageId
			, includeInactive = true
			, selectFields    = [ "title" ]
		);
		if ( not prc.parentPage.recordCount ) {
			messageBox.error( translateResource( "cms:sitetree.page.not.found.error" ) );
			setNextEvent( url = event.buildAdminLink( linkTo="sitetree" ) );
		}

		if ( !pageTypesService.pageTypeExists( pageType ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( pageType );

		prc.mainFormName  = "preside-objects.page.add";
		prc.mergeFormName = _getPageTypeFormName( pageType, "add" );

		if ( _isManagedPage( parentPageId, rc.page_type ) ) {
			prc.cancelLink = event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#parentPageId#&pageType=#rc.page_type#" );
		} else {
			prc.cancelLink = event.buildAdminLink( linkTo="sitetree" );
		}

		_pageCrumbtrail( argumentCollection=arguments, pageId=parentPageId, pageTitle=prc.parentPage.title );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.addPage.title" )
			, link  = ""
		);
	}

	public void function addPageAction( event, rc, prc ) {
		var parent            = rc.parent_page ?: "";
		var pageType          = rc.page_type   ?: "";
		var formName          = "preside-objects.page.add";
		var saveAsDraft       = ( rc._saveaction ?: "" ) != "publish";
		var formData          = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";

		_checkPermissions( argumentCollection=arguments, key="add", pageId=parent );
		if ( saveAsDraft ) {
			_checkPermissions( argumentCollection=arguments, key="saveDraft", pageId=parent );
		} else {
			_checkPermissions( argumentCollection=arguments, key="publish", pageId=parent );
		}

		if ( !pageTypesService.pageTypeExists( pageType ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( pageType );
		var mergeFormName = _getPageTypeFormName( pageType, "add" );
		if ( Len( Trim( mergeFormName ) ) ) {
			formName = formsService.getMergedFormName( formName, mergeFormName );
		}

		formData             = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );
		formData.parent_page = parent;
		formData.page_type   = rc.page_type;

		validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.addPage" ), persistStruct=persist );
		}

		newId = siteTreeService.addPage( argumentCollection = formData, isDraft=saveAsDraft );

		websitePermissionService.syncContextPermissions(
			  context       = "page"
			, contextKey    = newId
			, permissionKey = "pages.access"
			, grantBenefits = ListToArray( rc.grant_access_to_benefits ?: "" )
			, denyBenefits  = ListToArray( rc.deny_access_to_benefits  ?: "" )
			, grantUsers    = ListToArray( rc.grant_access_to_users    ?: "" )
			, denyUsers     = ListToArray( rc.deny_access_to_users     ?: "" )
		);


		messageBox.info( translateResource( uri="cms:sitetree.pageAdded.confirmation" ) );
		if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
			persist = {
				  _addanother = 1
				, active      = formData.active ?: 0
			}

			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#parent#&page_type=#rc.page_type#" ), persistStruct=persist );
		} else {
			if ( _isManagedPage( formData.parent_page, formData.page_type ) ) {
				setNextEvent( url=event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#formData.parent_page#&pageType=#formData.page_type#" ) );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#newId#" ) );
			}
		}
	}

	public void function editPage( event, rc, prc ) {
		var pageId           = rc.id               ?: "";
		var validationResult = rc.validationResult ?: "";
		var pageType         = "";

		_checkPermissions( argumentCollection=arguments, key="edit", pageId=pageId );
		prc.page         = _getPageAndThrowOnMissing( argumentCollection=arguments, allowVersions=true );
		prc.canPublish   = _checkPermissions( argumentCollection=arguments, key="publish", pageId=pageId, throwOnError=false );
		prc.canSaveDraft = _checkPermissions( argumentCollection=arguments, key="saveDraft", pageId=pageId, throwOnError=false );
		rc._backToEdit   = IsTrue( cookieService.getVar( "sitetree_editPage_backToEdit", "" ) );
		prc.childCount   = rc.child_count ?: "";

		if( !len( prc.childCount ) ) {
			prc.childCount = siteTreeService.getTree( rootPageId=pageId, maxDepth=0 ).recordCount ?: 0;
		}

		var version = Val ( rc.version    ?: "" );

		if ( !prc.canPublish && !prc.canSaveDraft ) {
			event.adminAccessDenied();
		}

		if ( !pageTypesService.pageTypeExists( prc.page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( prc.page.page_type );
		prc.canActivate  = !IsTrue( prc.page._version_is_draft ) && !pageType.isSystemPageType() && _checkPermissions( argumentCollection=arguments, key="activate", pageId=pageId, throwOnError=false );

		prc.mainFormName  = "preside-objects.page.edit";
		prc.mergeFormName = _getPageTypeFormName( pageType, "edit" );

		prc.page = QueryRowToStruct( prc.page );
		var savedData = getPresideObject( pageType.getPresideObject() ).selectData( filter={ page = pageId }, fromVersionTable=( version > 0 ), specificVersion=version, allowDraftVersions=true  );
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

		prc.allowableChildPageTypes = getAllowableChildPageTypes( prc.page.page_type );
		prc.managedChildPageTypes   = getManagedChildPageTypes( prc.page.page_type );
		prc.isSystemPage            = isSystemPageType( prc.page.page_type );

		prc.canAddChildren     = _checkPermissions( argumentCollection=arguments, key="add"               , pageId=pageId, throwOnError=false ) && prc.allowableChildPageTypes != "none";
		prc.canDeletePage      = _checkPermissions( argumentCollection=arguments, key="trash"             , pageId=pageId, throwOnError=false ) && !prc.isSystemPage;
		prc.canSortChildren    = _checkPermissions( argumentCollection=arguments, key="sort"              , pageId=pageId, throwOnError=false ) && prc.managedChildPageTypes.len() || prc.childCount;
		prc.canManagePagePerms = _checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId, throwOnError=false );
		prc.canClone           = _checkPermissions( argumentCollection=arguments, key="clone"             , pageId=pageId, throwOnError=false ) && !prc.isSystemPage;

		prc.pageIsMultilingual     = multilingualPresideObjectService.isMultilingual( "page" );
		prc.pageTypeIsMultilingual = multilingualPresideObjectService.isMultilingual( pageType.getPresideObject() );
		prc.isMultilingual         = prc.pageIsMultilingual || prc.pageTypeIsMultilingual;
		prc.canTranslate           = prc.isMultilingual && _checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId, throwOnError=false );

		if ( _isManagedPage( prc.page.parent_page, prc.page.page_type ) ) {
			prc.backToTreeTitle = translateResource( uri="cms:sitetree.back.to.managed.pages.link", data=[
				translateResource( pageType.getName() )
			] );
			prc.backToTreeLink = event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#prc.page.parent_page#&pageType=#prc.page.page_type#" );
		} else {
			prc.backToTreeTitle = translateResource( "cms:sitetree.back.to.tree.link" );
			prc.backToTreeLink = event.buildAdminLink( linkto="sitetree", querystring="selected=" & prc.page.id );
		}

		if ( prc.canTranslate ) {
			prc.translations = multilingualPresideObjectService.getTranslationStatus( ( prc.pageIsMultilingual ? "page" : pageType.getPresideObject() ), id );
		}

		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
	}

	public void function editPageAction( event, rc, prc ) {
		var pageId            = event.getValue( "id", "" );
		var saveAsDraft       = ( rc._saveaction ?: "" ) != "publish";
		var validationRuleset = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";
		var formName          = "preside-objects.page.edit";
		var formData          = "";
		var page              = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="edit", pageId=pageId );

		if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( page.page_type );
		var mergeFormName = _getPageTypeFormName( pageType, "edit" )
		if ( Len( Trim( mergeFormName ) ) ) {
			formName = formsService.getMergedFormName( formName, mergeFormName );
		}

		formData         = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );
		formData.id      = pageId;
		validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ), persistStruct=persist );
		}

		try {
			siteTreeService.editPage( argumentCollection=formData, isDraft=saveAsDraft );
		} catch( "SiteTreeService.BadParent" e ) {
			validationResult.addError( fieldname="parent_page", message="cms:sitetree.validation.badparent.error" );

			messageBox.error( translateResource( "cms:sitetree.data.validation.error" ) );
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

		messageBox.info( translateResource( uri="cms:sitetree.pageEdited.confirmation" ) );
		cookieService.setVar( name="sitetree_editPage_backToEdit", value=false );
		if ( IsTrue( rc._backToEdit ?: "" ) ) {
			cookieService.setVar( name="sitetree_editPage_backToEdit", value=true );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ), persist="_backToEdit" );
		} else {
			if ( _isManagedPage( page.parent_page, page.page_type ) ) {
				setNextEvent( url=event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#page.parent_page#&pageType=#page.page_type#" ) );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#pageId#" ) );
			}
		}
	}

	public void function clonePage( event, rc, prc ) {
		var pageId           = rc.id               ?: "";
		var validationResult = rc.validationResult ?: "";
		var pageType         = "";

		_checkPermissions( argumentCollection=arguments, key="clone", pageId=pageId );
		prc.page         = _getPageAndThrowOnMissing( argumentCollection=arguments, allowVersions=true );
		prc.canPublish   = _checkPermissions( argumentCollection=arguments, key="publish", pageId=pageId, throwOnError=false );
		prc.canSaveDraft = _checkPermissions( argumentCollection=arguments, key="saveDraft", pageId=pageId, throwOnError=false );

		if ( !prc.canPublish && !prc.canSaveDraft ) {
			event.adminAccessDenied();
		}
		if ( !pageTypesService.pageTypeExists( prc.page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		prc.childCount   = siteTreeService.getTree( rootPageId=pageId, maxDepth=0 ).recordCount ?: 0;

		pageType = pageTypesService.getPageType( prc.page.page_type );

		prc.mainFormName  = "preside-objects.page.clone";
		prc.mergeFormName = _getPageTypeFormName( pageType, "clone" );

		prc.page = QueryRowToStruct( prc.page );
		var savedData = getPresideObject( pageType.getPresideObject() ).selectData( filter={ page = pageId }, fromVersionTable=false, allowDraftVersions=true  );
		StructAppend( prc.page, QueryRowToStruct( savedData ) );

		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sitetree.clonePage.crumb")
			, link  = ""
		);
		prc.pageTitle = translateResource( uri="cms:sitetree.clonePage.title", data=[ prc.page.title ] );
		prc.pageIcon  = "clone";
	}

	public void function clonePageAction( event, rc, prc ) {
		var pageId            = rc.id ?: "";
		var saveAsDraft       = IsTrue( rc.clone_save_as_draft    ?: "" );
		var cloneChildren     = IsTrue( rc.clone_include_children ?: "" );
		var validationRuleset = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";
		var formName          = "preside-objects.page.clone";
		var formData          = "";
		var page              = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="clone", pageId=pageId );

		if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( page.page_type );
		var mergeFormName = _getPageTypeFormName( pageType, "clone" )
		if ( Len( Trim( mergeFormName ) ) ) {
			formName = formsService.getMergedFormName( formName, mergeFormName );
		}

		formData = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );
		validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.clonePage", querystring="id=#pageId#" ), persistStruct=persist );
		}

		newId = siteTreeService.clonePage(
			  sourcePageId  = pageId
			, newPageData   = formData
			, createAsDraft = saveAsDraft
			, cloneChildren = cloneChildren
		);

		messageBox.info( translateResource( uri="cms:sitetree.pageCloned.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkto="sitetree", querystring="selected=#newId#", siteId=( formData.site ?: "" ) ) );
	}

	public void function discardDraftsAction( event, rc, prc ) {
		var pageId            = event.getValue( "id", "" );
		var page              = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="edit"     , pageId=pageId );
		_checkPermissions( argumentCollection=arguments, key="saveDraft", pageId=pageId );

		if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		siteTreeService.discardDrafts( pageId );

		messageBox.info( translateResource( uri="cms:sitetree.page.drafts.discarded.confirmation" ) );

		if ( _isManagedPage( page.parent_page, page.page_type ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#page.parent_page#&pageType=#page.page_type#" ) );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#pageId#" ) );
		}
	}

	public void function activatePageAction( event, rc, prc ) {
		var page   = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="activate", pageId=page.id );

		siteTreeService.editPage( id=page.id, active=true, skipAudit=true );
		event.audit(
			  action   = "activate_page"
			, type     = "sitetree"
			, detail   = QueryRowToStruct( page )
			, recordId = page.id
		);

		messageBox.info( translateResource( uri="cms:sitetree.page.activated.confirmation" ) );
		if ( _isManagedPage( page.parent_page, page.page_type ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#page.parent_page#&pageType=#page.page_type#" ) );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#page.id#" ) );
		}
	}

	public void function deactivatePageAction( event, rc, prc ) {
		var page   = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="activate", pageId=page.id );

		siteTreeService.editPage( id=page.id, active=false, skipAudit=true );
		event.audit(
			  action   = "deactivate_page"
			, type     = "sitetree"
			, detail   = QueryRowToStruct( page )
			, recordId = page.id
		);

		messageBox.info( translateResource( uri="cms:sitetree.page.deactivated.confirmation" ) );

		if ( _isManagedPage( page.parent_page, page.page_type ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="sitetree.managedChildren", querystring="parent=#page.parent_page#&pageType=#page.page_type#" ) );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#page.id#" ) );
		}
	}

	public void function translatePage( event, rc, prc ) {
		var pageId           = rc.id               ?: "";
		var validationResult = rc.validationResult ?: "";
		var pageType         = "";

		_checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId );
		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments, allowVersions=false, setVersion=false );

		prc.canPublish   = _checkPermissions( argumentCollection=arguments, key="publish"  , pageId=pageId, throwOnError=false );
		prc.canSaveDraft = _checkPermissions( argumentCollection=arguments, key="saveDraft", pageId=pageId, throwOnError=false );

		if ( !prc.canPublish && !prc.canSaveDraft ) {
			event.adminAccessDenied();
		}

		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		if ( !pageTypesService.pageTypeExists( prc.page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( prc.page.page_type );
		prc.pageTypeObjectName     = pageType.getPresideObject();
		prc.pageIsMultilingual     = multilingualPresideObjectService.isMultilingual( "page" );
		prc.pageTypeIsMultilingual = multilingualPresideObjectService.isMultilingual( prc.pageTypeObjectName );
		var isMultilingual         = prc.pageIsMultilingual || prc.pageTypeIsMultilingual;

		if ( !isMultilingual ) {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		var translationPageObject = multilingualPresideObjectService.getTranslationObjectName( "page" );
		var translationPageTypeObject = multilingualPresideObjectService.getTranslationObjectName( prc.pageTypeObjectName );

		prc.savedTranslation = {};

		var version = rc.version ?: versioningService.getLatestVersionNumber(
			  objectName = prc.pageIsMultilingual ? translationPageObject : translationPageTypeObject
			, filter     = { _translation_source_record=pageId, _translation_language=prc.language.id }
		);

		rc.version = rc.version ?: version;

		if ( prc.pageIsMultilingual ) {
			prc.mainFormName  = "preside-objects.#translationPageObject#.admin.edit";
			prc.mergeFormName = "";

			var translation = multiLingualPresideObjectService.selectTranslation( objectName="page", id=pageId, languageId=prc.language.id, useCache=false, version=version );

			for( var t in translation ) {
				prc.savedTranslation.append( t );
			}
		}
		if ( prc.pageTypeIsMultilingual ) {
			if ( prc.pageIsMultilingual ) {
				prc.mergeFormName  = "preside-objects.#translationPageTypeObject#.admin.edit";
			} else {
				prc.mainFormName  = "preside-objects.#translationPageTypeObject#.admin.edit";
				prc.mergeFormName = "";
			}

			if ( prc.pageIsMultilingual ) {
				version = versioningService.getLatestVersionNumber(
					  objectName = translationPageTypeObject
					, filter     = { _translation_source_record=pageId, _translation_language=prc.language.id }
				);
			}

			var translation = multiLingualPresideObjectService.selectTranslation( objectName=prc.pageTypeObjectName, id=pageId, languageId=prc.language.id, useCache=false, version=version );
			for( var t in translation ) {
				prc.savedTranslation.append( t );
			}
		}

		prc.translations = multilingualPresideObjectService.getTranslationStatus( ( prc.pageIsMultilingual ? "page" : prc.pageTypeObjectName ), pageId );
		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.translatepage.breadcrumb.title", data=[ prc.language.name ] )
			, link  = ""
		);
		prc.pageIcon  = "pencil";
		prc.pageTitle = translateResource( uri="cms:sitetree.translatepage.title", data=[ prc.page.title, prc.language.name ] );
	}

	public void function translatePageAction( event, rc, prc ) {
		var pageId            = rc.id       ?: "";
		var languageId        = rc.language ?: "";
		var saveAsDraft       = ( rc._saveaction ?: "" ) != "publish";
		var page              = _getPageAndThrowOnMissing( argumentCollection=arguments );
		var validationRuleset = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";
		var formData          = "";

		_checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId );

		var language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
			messageBox.error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}
		pageType = pageTypesService.getPageType( page.page_type );

		var pageIsMultilingual     = multilingualPresideObjectService.isMultilingual( "page" );
		var pageTypeIsMultilingual = multilingualPresideObjectService.isMultilingual( pageType.getPresideObject() );
		var isMultilingual         = pageIsMultilingual || pageTypeIsMultilingual;

		if ( !isMultilingual ) {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		var translationPageObject     = multilingualPresideObjectService.getTranslationObjectName( "page" );
		var translationPageTypeObject = multilingualPresideObjectService.getTranslationObjectName( pageType.getPresideObject() );
		var formName                  = "";
		var mergeFormName             = "";

		if ( pageIsMultilingual ) {
			formName  = "preside-objects.#translationPageObject#.admin.edit";
		}
		if ( pageTypeIsMultilingual ) {
			if ( pageIsMultilingual ) {
				mergeFormName  = "preside-objects.#translationPageTypeObject#.admin.edit";
			} else {
				formName  = "preside-objects.#translationPageTypeObject#.admin.edit";
			}
		}

		if ( Len( Trim( mergeFormName ) ) ) {
			formName = formsService.getMergedFormName( formName, mergeFormName );
		}

		formData = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );
		formData._translation_language = languageId
		formData.id = multilingualPresideObjectService.getExistingTranslationId(
			  objectName = pageIsMultilingual ? "page" : page.page_type
			, id         = pageId
			, languageId = languageId
		);

		validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.translatePage", querystring="id=#pageId#&language=#languageId#" ), persistStruct=persist );
		}

		if ( pageIsMultilingual ) {
			multilingualPresideObjectService.saveTranslation(
				  objectName = "page"
				, id         = pageId
				, data       = formData
				, languageId = languageId
				, isDraft    = saveAsDraft
			);
		}

		if ( pageTypeIsMultilingual ) {
			multilingualPresideObjectService.saveTranslation(
				  objectName = pageType.getPresideObject()
				, id         = pageId
				, data       = formData
				, languageId = languageId
				, isDraft    = saveAsDraft
			);
		}

		var auditDetail = QueryRowToStruct( page );
		auditDetail.languageId = languageId
		event.audit(
			  action   = "translate_page"
			, type     = "sitetree"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		messageBox.info( translateResource( uri="cms:sitetree.pageTranslated.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ) );
	}

	public void function translationHistory( event, rc, prc ) {
		var pageId     = rc.id ?: "";
		var languageId = rc.language ?: "";
		var pageType   = "";

		_checkPermissions( argumentCollection=arguments, key="viewversions", pageId=pageId );
		_checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId );

		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		prc.page                   = _getPageAndThrowOnMissing( argumentCollection=arguments );
		prc.pageType               = pageTypesService.getPageType( prc.page.page_type );
		prc.pageTypeObjectName     = prc.pageType.getPresideObject();
		prc.pageIsMultilingual     = multilingualPresideObjectService.isMultilingual( "page" );
		prc.pageTypeIsMultilingual = multilingualPresideObjectService.isMultilingual( prc.pageTypeObjectName );
		prc.versionedObjectName    = prc.pageIsMultilingual ? "page" : prc.pageTypeObjectName

		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.translatepage.breadcrumb.title", data=[ prc.language.name ] )
			, link  = event.buildAdminLink( linkto="sitetree.translatePage", queryString="id=#pageId#&language=#languageId#" )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.pageTranslationHistory.crumb", data=[ prc.page.title, prc.language.name ] )
			, link  = ""
		);

		prc.pageTitle = translateResource( uri="cms:sitetree.pageTranslationHistory.title", data=[ prc.page.title, prc.language.name ] )
		prc.pageIcon  = "history";
	}

	public void function trashPageAction( event, rc, prc ) {
		var pageId  = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="trash", pageId=pageId );

		if ( pageId eq prc.homepage.id ) {
			messageBox.error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		var page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		siteTreeService.trashPage( pageId );

		messageBox.info( translateResource( uri="cms:sitetree.pageTrashed.confirmation" ) );
		if ( _isManagedPage( page.parent_page, page.page_type ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.managedChildren", querystring="parent=#page.parent_page#&pagetype=#page.page_type#" ) );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree", querystring="selected=#page.parent_page#"  ) );
		}
	}

	public void function deletePageAction( event, rc, prc ) {
		var pageId = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="delete", pageId=pageId );

		if ( pageId eq prc.homepage.id ) {
			messageBox.error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		_getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		siteTreeService.permanentlyDeletePage( event.getValue( "id", "" ) );

		messageBox.info( translateResource( uri="cms:sitetree.pageDeleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree.trash" ) );
	}

	public void function emptyTrashAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="emptytrash" );

		siteTreeService.emptyTrash();

		messageBox.info( translateResource( uri="cms:sitetree.trashEmptied.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
	}

	public void function restorePage( event, rc, prc ) {
		var pageId = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="restore", pageId=pageId );

		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		prc.page = QueryRowToStruct( prc.page );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.restorePage.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function restorePageAction( event, rc, prc ) {
		var pageId            = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="restore", pageId=pageId );
		_getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		var formName          = "preside-objects.page.restore";
		var formData          = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );
		var validationResult  = "";
		var newId             = "";
		var persist           = "";

		validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext="page", permissionContextKeys=( prc.pagePermissionContext ?: [] ) );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:sitetree.data.validation.error" ) );
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

		messageBox.info( translateResource( uri="cms:sitetree.pageRestored.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", queryString="selected=#pageId#" ) );
	}

	public void function reorderChildren( event, rc, prc ) {
		var pageId = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="sort", pageId=pageId );

		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		prc.childPages = siteTreeService.getDescendants(
			  id       = pageId
			, depth        = 1
			, selectFields = [ "id", "title" ]
		);

		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.reorderChildren.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function reorderChildrenAction( event, rc, prc ) {
		var pageId  = event.getValue( "id", "" );
		var page    = siteTreeService.getPage( pageId );

		_checkPermissions( argumentCollection=arguments, key="sort", pageId=pageId );

		var sortedPages = ListToArray( event.getValue( "ordered", "" ) );
		var i = 0;

		for( i=1; i lte ArrayLen( sortedPages ); i++ ){
			siteTreeService.editPage(
				  id             = sortedPages[i]
				, sort_order     = i
				, skipAudit      = true
				, skipVersioning = true
			);
		}
		event.audit(
			  action   = "reorder_children"
			, type     = "sitetree"
			, detail   = QueryRowToStruct( page )
			, recordId = page.id
		);

		messageBox.info( translateResource( uri="cms:sitetree.childrenReordered.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", queryString="selected=#pageId#" ) );
	}

	public void function editPagePermissions( event, rc, prc ) {
		var pageId   = event.getValue( "id", "" );

		_checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId );

		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		prc.inheritedPermissionContext = _getPagePermissionContext( argumentCollection=arguments, includePageId=false );

		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.editPagePermissions.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function editPagePermissionsAction( event, rc, prc ) {
		var pageId = event.getValue( "id", "" );
		var page   = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId );

		if ( runEvent( event="admin.Permissions.saveContextPermsAction", private=true ) ) {
			event.audit(
				  action   = "edit_page_admin_permissions"
				, type     = "sitetree"
				, detail   = QueryRowToStruct( page )
				, recordId = pageId
			);
			messageBox.info( translateResource( uri="cms:sitetree.cmsPermsSaved.confirmation", data=[ page.title ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.index", queryString="selected=#pageId#" ) );
		}

		messageBox.error( translateResource( uri="cms:sitetree.cmsPermsSaved.error", data=[ page.title ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id=#pageId#" ) );
	}

	public void function pageHistory( event, rc, prc ) {
		var pageId   = event.getValue( "id", "" );
		var pageType = "";

		_checkPermissions( argumentCollection=arguments, key="viewversions", pageId=pageId );
		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_pageCrumbtrail( argumentCollection=arguments, pageId=prc.page.id, pageTitle=prc.page.title );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sitetree.pageHistory.crumb", data=[ prc.page.title ] )
			, link  = ""
		);
	}

	public void function pageTypeDialog( event, rc, prc ) {
		var parentPage = sitetreeService.getPage( id=rc.parentPage, selectFields=[ "page_type" ] );

		if ( parentPage.recordCount ) {
			prc.pageTypes = pageTypesService.listPageTypes( allowedBeneathParent=parentPage.page_type, includeSystemPageTypes=false );
		} else {
			prc.pageTypes = pageTypesService.listPageTypes( includeSystemPageTypes=false );
		}

		event.setView( view="admin/sitetree/pageTypeDialog", nolayout=true );
	}

	public void function getPagesForAjaxPicker( event, rc, prc ) {
		var extraFilters   = [];
		var filterByFields = ListToArray( rc.filterByFields ?: "" );
		for( var filterByField in filterByFields ) {
			filterValue = rc[filterByField] ?: "";
			if( !isEmpty( filterValue ) ){
				extraFilters.append({ filter = { "#filterByField#" = listToArray( filterValue ) } });
			}
		}

		var records = siteTreeService.getPagesForAjaxSelect(
			  maxRows      = rc.maxRows   ?: 1000
			, searchQuery  = rc.q         ?: ""
			, childPage    = rc.childPage ?: ""
			, ids          = ListToArray( rc.values ?: "" )
			, site         = rc.site      ?: ""
			, extraFilters = extraFilters
		);
		var preparedPages = [];

		for ( record in records ) {
			if ( IsNull( record.parent ?: ""  ) || !Len( Trim( record.parent ?: "" ) ) ) {
				record.parent = "";
			}
			if ( record.depth ) {
				record.parent = RepeatString( "&rarr;", record.depth ) & record.parent;
			}

			record.icon = translateResource( "page-types.#record.page_type#:iconclass", "fa-file-o" );

			preparedPages.append( record );
		}

		event.renderData( type="json", data=preparedPages );
	}

	public void function ajaxSearch( event, rc, prc ) {
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

			record.icon = translateResource( "page-types.#record.page_type#:iconclass", "fa-file-o" );

			preparedPages.append( record );
		}

		event.renderData( type="json", data=preparedPages );
	}

	public void function getPageHistoryForAjaxDataTables( event, rc, prc ) {
		var pageId = rc.id     ?: "";

		_checkPermissions( argumentCollection=arguments, key="viewversions", pageId=pageId );

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = "page"
				, recordId   = pageId
				, actionsView = "admin/sitetree/_historyActions"
			}
		);
	}

	public void function getPageTranslationHistoryForAjaxDataTables( event, rc, prc ) {
		var pageId     = rc.id ?: "";
		var languageId = rc.language ?: "";

		_checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId );
		_checkPermissions( argumentCollection=arguments, key="viewversions", pageId=pageId );

		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		var page                   = _getPageAndThrowOnMissing( argumentCollection=arguments );
		var pageType               = pageTypesService.getPageType( page.page_type );
		var pageTypeObjectName     = pageType.getPresideObject();
		var pageIsMultilingual     = multilingualPresideObjectService.isMultilingual( "page" );
		var pageTypeIsMultilingual = multilingualPresideObjectService.isMultilingual( pageTypeObjectName );
		var versionedObjectName    = pageIsMultilingual ? "page" : pageTypeObjectName

		runEvent(
			  event          = "admin.DataManager._getTranslationRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = versionedObjectName
				, recordId   = pageId
				, languageId = languageId
				, gridFields = ( rc.gridFields ?: "datemodified,_version_author,title" )
				, actionsView = "admin/sitetree/_translationHistoryActions"
			}
		);
	}



	public void function managedChildren( event, rc, prc ) {
		var parentId = rc.parent   ?: "";
		var pageType = rc.pageType ?: "";

		prc.gridFields      = _getObjectFieldsForGrid( pageType );
		prc.cleanGridFields = _cleanGridFields( prc.gridFields );
		prc.gridFieldTitles = _getGridFieldTitles( prc.gridFields, pageType );
		prc.parentPage      = _getPageAndThrowOnMissing( argumentCollection=arguments, pageId=parentId );

		if ( !Len( Trim( pageType ) ) || !pageTypesService.pageTypeExists( pageType ) || !ListFindNoCase( pageTypesService.getPageType( prc.parentPage.page_type ).getManagedChildTypes(), pageType ) ) {
			event.notFound();
		}

		_checkPermissions( argumentCollection=arguments, key="navigate", pageId=parentId );

		prc.pageTitle    = translateResource( uri="cms:sitetree.manage.type", data=[ LCase( translateResource( "page-types.#pageType#:name" ) ) ] );
		prc.pageSubTitle = translateResource( uri="cms:sitetree.manage.type.subtitle", data=[ LCase( translateResource( "page-types.#pageType#:name" ) ), prc.parentPage.title ] );;
		prc.pageIcon     = translateResource( "page-types.#pageType#:iconClass" );
		prc.canAddChildren = _checkPermissions( argumentCollection=arguments, key="add", pageId=parentId, throwOnError=false );

		_pageCrumbtrail( argumentCollection=arguments, pageId=parentId, pageTitle=prc.parentPage.title );
		event.addAdminBreadCrumb(
			  title = prc.pageTitle
			, link  = event.buildAdminLink( linkTo="sitetree.managedChildren", queryString="parent=#parentId#&pageType=#pageType#" )
		);
	}

	public void function getManagedPagesForAjaxDataTables( event, rc, prc ) {
		var parentId         = rc.parent   ?: "";
		var pageType         = rc.pageType ?: "";
		var gridFields       = ListToArray( rc.gridFields );
		var cleanGridFields  = _cleanGridFields( gridFields );
		var defaultSortOrder = _getSortOrderForGrid( pageType );

		prc.parentPage = _getPageAndThrowOnMissing( argumentCollection=arguments, pageId=parentId );

		if ( !Len( Trim( pageType ) ) || !pageTypesService.pageTypeExists( pageType ) || !ListFindNoCase( pageTypesService.getPageType( prc.parentPage.page_type ).getManagedChildTypes(), pageType ) ) {
			event.notFound();
		}


		var optionsCol = [];
		var statusCol  = [];
		var dtHelper   = getModel( "JQueryDatatablesHelpers" );
		var sortOrder  = dtHelper.getSortOrder();
		var results    = siteTreeService.getManagedChildrenForDataTable(
			  objectName   = pageType
			, parentId     = parentId
			, pageType     = pageType
			, selectFields = gridFields
			, startRow     = dtHelper.getStartRow()
			, maxRows      = dtHelper.getMaxRows()
			, orderBy      = sortOrder.len() ? sortOrder : defaultSortOrder
			, searchQuery  = dtHelper.getSearchQuery()
		);

		var records = Duplicate( results.records );

		for( var record in records ){
			for( var field in gridFields ){
				var objectName = ListLen( field, "." ) > 1 ? ListFirst( field, "." ) : pageType;
				field = ListLen( field, "." ) > 1 ? ListRest( field, "." ) : field;

				records[ field ][ records.currentRow ] = renderField( objectName, field, record[ field ], [ "adminDataTable", "admin" ] );
			}
			var args = record;
			args.title 			= record[ ListLast( gridFields[1], "." ) ];
			args.canEdit        = _checkPermissions( argumentCollection=arguments, key="edit"        , pageId=args.id, throwOnError=false );
			args.canDelete      = _checkPermissions( argumentCollection=arguments, key="delete"      , pageId=args.id, throwOnError=false );
			args.canViewHistory = _checkPermissions( argumentCollection=arguments, key="viewversions", pageId=args.id, throwOnError=false );
			args.is_draft       = IsTrue( record._version_is_draft   );
			args.has_drafts     = IsTrue( record._version_has_drafts );
			args.canActivate    = !args.is_draft && _checkPermissions( argumentCollection=arguments, key="activate", pageId=args.id, throwOnError=false );
			args.isActive       = IsTrue( record.active );

			ArrayAppend( optionsCol, renderView( view="/admin/sitetree/_managedPageGridActions", args=record ) );
			ArrayAppend( statusCol, renderView( view="/admin/sitetree/_nodeStatus", args=record ) );
		}

		QueryAddColumn( records, "status" , statusCol );
		QueryAddColumn( records, "_options" , optionsCol );
		ArrayAppend( cleanGridFields, "status" );
		ArrayAppend( cleanGridFields, "_options" );

		event.renderData( type="json", data=dtHelper.queryToResult( records, cleanGridFields, results.totalRecords ) );
	}

	public void function previewPage( event, rc, prc ) {
		setNextEvent( url=event.buildLink( page=( rc.id ?: "" ), forceDomain=true ) );
	}

	public void function clearPageCacheAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="clearcaches" );

		var pageId = rc.id ?: "";

		if ( pageId.isEmpty() ) {
			getController().getCachebox().clearAll();
			announceInterception( "onClearCaches", {} );

			event.audit(
				  action = "clear_page_cache"
				, type   = "sitetree"
			);
		} else {
			var page = _getPageAndThrowOnMissing( argumentCollection=arguments );

			var pageUrl    = event.buildLink( page=pageId ).reReplace( "^https?://.*?/", "/" );
			var sectionUrl = pageUrl.reReplace( "\.html$", "/" );

			pageCache.clearByKeySnippet( pageUrl );
			pageCache.clearByKeySnippet( sectionUrl );

			announceInterception( "onClearPageCaches", {
				  pageUrl    = pageUrl
				, sectionUrl = sectionUrl
			} );

			event.audit(
				  action   = "clear_cache_for_page"
				, type     = "sitetree"
				, detail   = QueryRowToStruct( page )
				, recordId = page.id
			);
		}

		messagebox.info( translateResource( "cms:sitetree.flush.cache.confirmation" ) );

		setNextEvent( url=event.buildAdminLink( "sitetree" ) );
	}

<!--- private viewlets --->
	private string function searchBox( event, rc, prc, args={} ) {
		var prefetchCacheBuster = datamanagerService.getPrefetchCachebusterForAjaxSelect( "page" );

		args.prefetchUrl = event.buildAdminLink( linkTo="sitetree.ajaxSearch", querystring="maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#" );
		args.remoteUrl   = event.buildAdminLink( linkTo="sitetree.ajaxSearch", querystring="q=%QUERY" );

		return renderView( view="/admin/sitetree/_searchBox", args=args );
	}

<!--- private helpers --->
	private boolean function _checkPermissions( event, rc, prc, required string key, string pageId="", string prefix="sitetree.", boolean throwOnError=true ) {
		var permitted = "";
		var permKey   = arguments.prefix & arguments.key;

		if ( Len( Trim( arguments.pageId ) ) ) {
			permitted = hasCmsPermission( permissionKey=permKey, context="page", contextKeys=_getPagePermissionContext( argumentCollection=arguments ) );

		} else {
			permitted = hasCmsPermission( permissionKey=permKey );
		}

		if ( arguments.throwOnError && !permitted ) {
			event.adminAccessDenied();
		}

		return permitted;
	}

	private string function _getPageTypeFormName( required any pageType, required string action ) {
		var specificForm = "";
		var defaultForm  = pageType.getDefaultForm();

		switch( arguments.action ) {
			case "add"      : specificForm = pageType.getAddForm(); break;
			case "edit"     : specificForm = pageType.getEditForm(); break;
			case "translate": specificForm = pageType.getTranslateForm(); break;
			case "clone"    : specificForm = pageType.getCloneForm(); break;
			default: return "";
		}

		if ( formsService.formExists( specificForm ) ) {
			return specificForm;
		}
		return formsService.formExists( defaultForm ) ? defaultForm : "";
	}

	private query function _getPageAndThrowOnMissing( event, rc, prc, pageId, includeTrash=false, allowVersions=false, setVersion=true ) {
		var pageId  = arguments.pageId        ?: ( rc.id ?: "" );
		var version = arguments.allowVersions ? ( rc.version ?: versioningService.getLatestVersionNumber( "page", pageId ) ) : 0;
		var page    = siteTreeService.getPage(
			  id              = pageId
			, version         = Val( version )
			, includeInactive = true
			, includeTrash    = arguments.includeTrash
			, allowDrafts     = true
			, useCache        = false
		);

		if ( !page.recordCount ) {
			messageBox.error( translateResource( "cms:sitetree.page.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		if ( arguments.setVersion ) {
			rc.version = rc.version ?: version;
		}

		return page;
	}

	private array function _getPagePermissionContext( event, rc, prc, pageId, includePageId=true ) {
		var pageId   = arguments.pageId ?: ( rc.id ?: "" );
		var cacheKey = "pagePermissionContext";

		if ( StructKeyExists( prc, cacheKey ) ) {
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

	private boolean function _isManagedPage( required string parentId, required string pageType ) {
		var parent = siteTreeService.getPage( id=parentId, selectFields=[ "page_type" ] );

		if ( !parent.recordCount ) {
			return false;
		}

		var managedTypesForParent = pageTypesService.getPageType( parent.page_type ).getManagedChildTypes();

		return managedTypesForParent.len() && ListFindNoCase( managedTypesForParent, arguments.pageType );
	}

	private void function _pageCrumbtrail( event, rc, prc, pageId, pageTitle ) {
		var ancestors = sitetreeService.getAncestors( id=arguments.pageId, selectFields=[ "id", "title" ] );

		for( var ancestor in ancestors ) {
			event.addAdminBreadCrumb(
				  title = ancestor.title
				, link  = event.buildAdminLink( linkto="sitetree.editpage", queryString="id=" & ancestor.id )
			);
		}

		event.addAdminBreadCrumb(
			  title = arguments.pageTitle
			, link  = event.buildAdminLink( linkto="sitetree.editpage", queryString="id=" & arguments.pageId )
		);
	}

	private array function _getObjectFieldsForGrid( required string objectName ) {
		return siteTreeService.listGridFields( arguments.objectName );
	}

	private string function _getSortOrderForGrid( required string objectName ) {
		return siteTreeService.getDefaultSortOrderForDataGrid( arguments.objectName );
	}

	private array function _cleanGridFields( required array gridFields ) {
		var cleanFields = [];

		for( var field in arguments.gridFields ) {
			cleanFields.append( ListLen( field, "." ) > 1 ? ListRest( field, "." ) : field );
		}

		return cleanFields;
	}

	private array function _getGridFieldTitles( required array gridFields, required string pageType ) {
		var titles = [];

		for( var field in arguments.gridFields ) {
			var objectName = ListLen( field, "." ) > 1 ? ListFirst( field, "." ) : arguments.pageType;
			var fieldName  = ListLen( field, "." ) > 1 ? ListRest( field, "." ) : field;
			var uriRoot    = presideObjectService.getResourceBundleUriRoot( objectName );

			titles.append(
				translateResource( uri="#uriRoot#field.#fieldName#.title", defaultValue=translateResource( "cms:preside-objects.default.field.#fieldName#.title" ) )
			);

		}

		return titles;
	}
}