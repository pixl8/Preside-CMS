component extends="preside.system.base.AdminHandler" {

	property name="siteTreeService"                  inject="siteTreeService";
	property name="formsService"                     inject="formsService";
	property name="pageTypesService"                 inject="pageTypesService";
	property name="validationEngine"                 inject="validationEngine";
	property name="websitePermissionService"         inject="websitePermissionService";
	property name="dataManagerService"               inject="dataManagerService";
	property name="multilingualPresideObjectService" inject="multilingualPresideObjectService";
	property name="messageBox"                       inject="coldbox:plugin:messageBox";

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
			, "page._hierarchy_slug as full_slug"
			, "page.trashed"
			, "page.access_restriction"
			, "page._hierarchy_depth"
			, "Count( child_pages.id ) as child_count"
		] );

		var additionalNodeArgs = {
			  editPageBaseLink            = event.buildAdminLink( linkTo="sitetree.editPage"           , queryString="id={id}"                           )
			, pageTypeDialogBaseLink      = event.buildAdminLink( linkTo="sitetree.pageTypeDialog"     , queryString="parentPage={id}"                   )
			, addPageBaseLink             = event.buildAdminLink( linkTo='sitetree.addPage'            , querystring='parent_page={id}&page_type={type}' )
			, trashPageBaseLink           = event.buildAdminLink( linkTo="sitetree.trashPageAction"    , queryString="id={id}"                           )
			, pageHistoryBaseLink         = event.buildAdminLink( linkTo="sitetree.pageHistory"        , queryString="id={id}"                           )
			, editPagePermissionsBaseLink = event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id={id}"                           )
			, reorderChildrenBaseLink     = event.buildAdminLink( linkTo="sitetree.reorderChildren"    , queryString="id={id}"                           )
			, previewPageBaseLink         = event.buildAdminLink( linkTo="sitetree.previewPage"        , queryString="id={id}"                           )
			, permission_context          = []
			, parent_restriction          = "inherited"
		};

		if ( ancestors.recordCount ) {
			additionalNodeArgs.permission_context = ValueArray( ancestors.id );
			additionalNodeArgs.permission_context.reverse();
		}
		additionalNodeArgs.permission_context.prepend( parentId );

		if ( parentPage.access_restriction != "inherited" ) {
			additionalNodeArgs.parent_restriction = parentPage.access_restriction;
		} else {
			for( var i=ancestors.recordcount; i>0; i-- ) {
				if ( ancestors.access_restriction[i] != "inherited" ) {
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
		prc.treeTrash = siteTreeService.getTree( trash = true, format="nestedArray", selectFields=[ "id", "parent_page", "title", "slug", "active", "page_type", "datecreated", "datemodified", "_hierarchy_slug as full_slug", "trashed", "access_restriction" ] );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sitetree.trash.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="sitetree.trash" )
		);
	}

	public void function addPage( event, rc, prc ) {
		var parentPageId = rc.parent_page ?: "";
		var pageType     = rc.page_type ?: "";

		_checkPermissions( argumentCollection=arguments, key="add", pageId=parentPageId );

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
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#newId#" ) );
		}
	}

	public void function editPage( event, rc, prc ) {
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

		prc.allowableChildPageTypes = getAllowableChildPageTypes( prc.page.page_type );
		prc.managedChildPageTypes   = getManagedChildPageTypes( prc.page.page_type );
		prc.isSystemPage            = isSystemPageType( prc.page.page_type );

		prc.canAddChildren     = _checkPermissions( argumentCollection=arguments, key="add"               , pageId=pageId, throwOnError=false ) && prc.allowableChildPageTypes != "none";
		prc.canDeletePage      = _checkPermissions( argumentCollection=arguments, key="trash"             , pageId=pageId, throwOnError=false ) && !prc.isSystemPage;
		prc.canSortChildren    = _checkPermissions( argumentCollection=arguments, key="sort"              , pageId=pageId, throwOnError=false );
		prc.canManagePagePerms = _checkPermissions( argumentCollection=arguments, key="manageContextPerms", pageId=pageId, throwOnError=false );

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


		setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#pageId#" ) );
	}

	public void function translatePage( event, rc, prc ) {
		var pageId           = rc.id               ?: "";
		var validationResult = rc.validationResult ?: "";
		var version          = Val ( rc.version    ?: "" );
		var pageType         = "";

		_checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId );
		prc.page = _getPageAndThrowOnMissing( argumentCollection=arguments, allowVersions=true );

		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		if ( !pageTypesService.pageTypeExists( prc.page.page_type ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
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
		var pageId            = event.getValue( "id", "" );
		var languageId        = event.getValue( "language", "" );
		var validationRuleset = "";
		var validationResult  = "";
		var newId             = "";
		var persist           = "";
		var formData          = "";
		var page              = _getPageAndThrowOnMissing( argumentCollection=arguments );

		_checkPermissions( argumentCollection=arguments, key="translate", pageId=pageId );

		var language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.editpage", queryString="id=#pageId#" ) );
		}

		if ( !pageTypesService.pageTypeExists( page.page_type ) ) {
			getPlugin( "messageBox" ).error( translateResource( "cms:sitetree.pageType.not.found.error" ) );
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

		formData         = event.getCollectionForForm( formName );
		validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			getPlugin( "MessageBox" ).error( translateResource( "cms:sitetree.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree.translatePage", querystring="id=#pageId#&language=#languageId#" ), persistStruct=persist );
		}

		formData._translation_active = IsTrue( rc._translation_active ?: "" );

		if ( pageIsMultilingual ) {
			multilingualPresideObjectService.saveTranslation(
				  objectName = "page"
				, id         = pageId
				, data       = formData
				, languageId = languageId
			);
		}

		if ( pageTypeIsMultilingual ) {
			multilingualPresideObjectService.saveTranslation(
				  objectName = pageType.getPresideObject()
				, id         = pageId
				, data       = formData
				, languageId = languageId
			);
		}


		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageTranslated.confirmation" ) );
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
			getPlugin( "MessageBox" ).error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		var page = _getPageAndThrowOnMissing( argumentCollection=arguments );

		siteTreeService.trashPage( pageId );

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageTrashed.confirmation" ) );
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
			getPlugin( "MessageBox" ).error( translateResource( uri="cms:sitetree.pageDelete.error.root.page" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sitetree" ) );
		}

		_getPageAndThrowOnMissing( argumentCollection=arguments, includeTrash=true );

		siteTreeService.permanentlyDeletePage( event.getValue( "id", "" ) );

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.pageDeleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree.trash" ) );
	}

	public void function emptyTrashAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="emptytrash" );

		siteTreeService.emptyTrash();

		getPlugin( "MessageBox" ).info( translateResource( uri="cms:sitetree.trashEmptied.confirmation" ) );
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

		_checkPermissions( argumentCollection=arguments, key="viewversion", pageId=pageId );

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

		prc.parentPage = _getPageAndThrowOnMissing( argumentCollection=arguments, pageId=parentId );

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
		var parentId = rc.parent   ?: "";
		var pageType = rc.pageType ?: "";

		prc.parentPage = _getPageAndThrowOnMissing( argumentCollection=arguments, pageId=parentId );

		if ( !Len( Trim( pageType ) ) || !pageTypesService.pageTypeExists( pageType ) || !ListFindNoCase( pageTypesService.getPageType( prc.parentPage.page_type ).getManagedChildTypes(), pageType ) ) {
			event.notFound();
		}


		var optionsCol = [];
		var dtHelper   = getMyPlugin( "JQueryDatatablesHelpers" );
		var gridFields = [ "title", "active", "datecreated" ];
		var results    = siteTreeService.getManagedChildrenForDataTable(
			  parentId     = parentId
			, pageType     = pageType
			, selectFields = gridFields
			, startRow     = dtHelper.getStartRow()
			, maxRows      = dtHelper.getMaxRows()
			, orderBy      = dtHelper.getSortOrder()
			, searchQuery  = dtHelper.getSearchQuery()
		);

		var records = Duplicate( results.records );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( "page", field, record[ field ], [ "adminDataTable", "admin" ] );
			}
			var args = record;
			args.canEdit        = _checkPermissions( argumentCollection=arguments, key="edit"        , pageId=args.id, throwOnError=false );
			args.canDelete      = _checkPermissions( argumentCollection=arguments, key="delete"      , pageId=args.id, throwOnError=false );
			args.canViewHistory = _checkPermissions( argumentCollection=arguments, key="viewversions", pageId=args.id, throwOnError=false );

			ArrayAppend( optionsCol, renderView( view="/admin/sitetree/_managedPageGridActions", args=record ) );
		}

		QueryAddColumn( records, "_options" , optionsCol );
		ArrayAppend( gridFields, "_options" );

		event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
	}

	public void function previewPage( event, rc, prc ) {
		setNextEvent( url=event.buildLink( page=( rc.id ?: "" ) ) );
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
			default: return "";
		}

		if ( formsService.formExists( specificForm ) ) {
			return specificForm;
		}
		return formsService.formExists( defaultForm ) ? defaultForm : "";
	}

	private query function _getPageAndThrowOnMissing( event, rc, prc, pageId, includeTrash=false, allowVersions=false ) {
		var pageId  = arguments.pageId        ?: ( rc.id ?: "" );
		var version = arguments.allowVersions ? ( rc.version ?: 0 ) : 0;
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

	private array function _getPagePermissionContext( event, rc, prc, pageId, includePageId=true ) {
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
}