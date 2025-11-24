/**
 * @feature admin and sites
 */
component extends="preside.system.base.AdminHandler" {

	property name="siteService"     inject="siteService";
	property name="siteTreeService" inject="siteTreeService";
	property name="cloningService"  inject="presideObjectCloningService";
	property name="siteDao"         inject="presidecms:object:site";
	property name="aliasDao"        inject="presidecms:object:site_alias_domain";
	property name="redirectDao"     inject="presidecms:object:site_redirect_domain";
	property name="messagebox"      inject="messagebox@cbmessagebox";

	public void function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "sites" ) ) {
			event.notFound();
		}
	}

	public void function manage( event, rc, prc ) {
		_checkPermissions( event );
		_addRootBreadcrumb( event );

		prc.pageIcon     = "globe";
		prc.pageTitle    = translateResource( "cms:sites.manage.title" );
		prc.pageSubTitle = translateResource( "cms:sites.manage.subtitle" );
	}

	public void function addSite() {
		_checkPermissions( event );

		_addRootBreadcrumb( event );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sites.addSite.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="sites.addSite" )
		);

		prc.pageIcon  = "globe";
		prc.pageTitle = translateResource( uri="cms:sites.addSite.title" );

		event.setView( "/admin/sites/addSite" );
	}

	public void function addSiteAction( event, rc, prc ) {
		_checkPermissions( event );

		var siteID = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "site"
				, errorAction       = "sites.addSite"
				, redirectOnSuccess = false
				, audit             = true
				, auditAction       = "add_site"
				, auditType         = "sitemanager"
			}
		);

		siteTreeService.ensureSystemPagesExistForSite( siteId );
		siteService.syncSiteRedirectDomains( siteId, rc.redirect_domains ?: "" );
		siteService.syncSiteAliasDomains( siteId, rc.alias_domains ?: "" );

		messageBox.info( translateResource( "cms:sites.added.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
	}


	public void function editSite() {
		_checkPermissions( event );
		var siteId       = rc.id     ?: "";
		var manageAction = rc.action ?: "";
		prc.record       = siteDao.selectData( id=siteId );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:sites.siteNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		var aliasDomains = aliasDao.selectData( filter={ site=siteId } );
		if ( aliasDomains.recordCount ) {
			prc.record.alias_domains = ValueList( aliasDomains.domain, Chr(13) & Chr(10) );
		}
		var redirectDomains = redirectDao.selectData( filter={ site=siteId } );
		if ( redirectDomains.recordCount ) {
			prc.record.redirect_domains = ValueList( redirectDomains.domain, Chr(13) & Chr(10) );
		}

		_addRootBreadcrumb( event );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sites.editsite.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="sites.editSite", queryString="id=#siteId#" )
		);

		prc.pageIcon     = "globe";
		prc.pageTitle    = translateResource( uri="cms:sites.editSite.title", data=[ prc.record.name ?: "" ] );
		prc.cancelAction = len( manageAction ) ? event.buildAdminLink( linkTo='sites.manage' ) : event.buildAdminLink( linkTo='sitetree' );
		event.setView( "/admin/sites/editSite" );
	}

	public void function editSiteAction( event, rc, prc ) {
		_checkPermissions( event );
		var siteId = rc.id ?: "";

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "site"
				, errorAction       = "sites.editSite"
				, redirectOnSuccess = false
				, audit             = true
				, auditAction       = "edit_site"
				, auditType         = "sitemanager"
			}
		);

		siteService.syncSiteRedirectDomains( siteId, rc.redirect_domains ?: "" );
		siteService.syncSiteAliasDomains( siteId, rc.alias_domains ?: "" );

		messageBox.info( translateResource( "cms:sites.saved.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
	}

	public void function cloneSite() {
		_checkPermissions( event );
		var siteId       = rc.id     ?: "";
		prc.record       = siteDao.selectData( id=siteId );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:sites.siteNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}
		prc.record = queryRowToStruct( prc.record );


		_addRootBreadcrumb( event );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sites.clonesite.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="sites.cloneSite", queryString="id=#siteId#" )
		);

		prc.pageIcon      = "clone";
		prc.pageTitle     = translateResource( uri="cms:sites.clonesite.title", data=[ prc.record.name ?: "" ] );

		prc.record.name   = "";
		prc.cancelAction  = event.buildAdminLink( linkTo='sites.manage' );
		prc.formAction    = event.buildAdminLink( linkTo='sites.cloneSiteAction' );
		prc.cloneFormName = "preside-objects.site.admin.clone";
	}

	public void function cloneSiteAction( event, rc, prc ) {
		_checkPermissions( event );

		var siteId           = rc.id ?: "";
		var formName         = "preside-objects.site.admin.clone";
		var formData         = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext="site", permissionContextKeys=[ siteId ] );
		var validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext="site", permissionContextKeys=[ siteId ] );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="sites.clonesite", querystring="id=#siteId#" ), persistStruct=persist );
		}

		var newSiteId = cloningService.cloneRecord(
			  objectName = "site"
			, recordId   = siteId
			, data       = formData
		);

		siteTreeService.clonePage(
			  sourcePageId  = siteTreeService.getSiteHomepage( site=siteId ).id
			, newPageData   = { site=newSiteId }
			, createAsDraft = false
			, cloneChildren = true
		);

		event.audit(
			  action   = "clone_site"
			, type     = "sitemanager"
			, recordId = newSiteId
			, detail   = { id=newSiteId, objectName="site" }
		);

		messageBox.info( translateResource( "cms:sites.clonesite.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sitetree", siteId=newSiteId ) );

	}

	public void function editPermissions( event, rc, prc ) {
		_checkPermissions( event );

		prc.record = siteDao.selectData( id=rc.id ?: "" );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:sites.siteNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		_addRootBreadcrumb( event );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sites.editPermissions.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="sites.editPermissions", queryString="id=#(rc.id ?: '')#" )
		);

		prc.pageIcon  = "globe";
		prc.pageTitle = translateResource( uri="cms:sites.editPermissions.title", data=[ prc.record.name ?: "" ] );

		event.setView( "/admin/sites/editPermissions" );
	}

	public void function saveSitePermissionsAction( event, rc, prc ) {
		var siteId = rc.id ?: "";

		_checkPermissions( event );

		var success = runEvent( event="admin.Permissions.saveContextPermsAction", private=true );

		if ( success ) {
			messageBox.info( translateResource( uri="cms:sites.permsSaved.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}

		messageBox.error( translateResource( uri="cms:sites.permsSaved.error" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sites.editPermissions", queryString="id=#siteId#" ) );
	}

	public void function deleteSite() {
		_checkPermissions( event );
		var siteId = rc.id     ?: "";

		if ( siteId == event.getSiteId() ) {
			messageBox.error( translateResource( uri="cms:sites.deletesite.error.active.site" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}

		prc.record = siteDao.selectData( id=siteId );
		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:sites.siteNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		_addRootBreadcrumb( event );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:sites.deletesite.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="sites.deletesite", queryString="id=#siteId#" )
		);

		prc.pageIcon     = "trash";
		prc.pageTitle    = translateResource( uri="cms:sites.deletesite.title", data=[ prc.record.name ?: "" ] );
		prc.cancelAction = event.buildAdminLink( linkTo='sites.manage' );
		prc.formAction   = event.buildAdminLink( linkTo='sites.deleteSiteAction' );
		prc.confirmationCode = LCase( ListFirst( CreateUUId(), "-" ) );
	}

	public void function deleteSiteAction() {
		_checkPermissions( event );

		var siteId = rc.id ?: "";
		var site   = siteDao.selectData( id=siteId );

		if ( siteId == event.getSiteId() ) {
			messageBox.error( translateResource( uri="cms:sites.deletesite.error.active.site" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}

		if ( !site.recordCount ) {
			messageBox.error( translateResource( uri="cms:sites.siteNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="sites.manage" ) );
		}

		var formName = "preside-objects.site.admin.delete";
		var formData = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );
		var userDetails = event.getAdminUserDetails();

		if ( formData.deletion_confirmation_text != userDetails.login_id && formData.deletion_confirmation_text != userDetails.email_address ) {
			validationResult.addError(
				  fieldname = "deletion_confirmation_text"
				, message   = "cms:sites.deletesite.confirmation.validation.mismatch"
			);

			setNextEvent( url=event.buildAdminLink( linkto="sites.deleteSite", queryString="id=#siteId#" ), persistStruct={ validationResult=validationResult } );
		}

		siteService.deleteSite( siteId );

		event.audit(
			  action   = "delete_site"
			, type     = "sitemanager"
			, recordId = siteId
			, detail   = { id=siteId, objectName="site" }
		);

		messagebox.info( translateResource( "cms:sites.deletesite.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkto="sites.manage" ) );
	}

	public void function setActiveSite( event, rc, prc ) {
		var activeSiteId = rc.id ?: "";

		if ( !Len( Trim( activeSiteId ) ) || !hasCmsPermission( "sites.navigate", "site", [ activeSiteId ] ) ) {
			event.adminAccessDenied();
		}

		var currentActiveSite = siteService.getActiveAdminSite( domain=cgi.server_name ?: "" );
		var newSite           = siteService.getSite( activeSiteId );

		if ( newSite.domain != currentActiveSite.domain ) {
			event.setSite( newSite );
			setNextEvent( url=event.buildAdminLink( linkto="sitetree.index" ) );
		}

		siteService.setActiveAdminSite( activeSiteId );
		setNextEvent( url=event.buildAdminLink( linkto="sitetree.index" ) );
	}

	public void function getSitesForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( event );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "site"
				, gridFields  = "name,domain,path"
				, actionsView = "/admin/sites/_sitesGridActions"
				, extraFilters = [ { filter="deleted is null or deleted = :deleted", filterParams={ deleted=false } } ]
			}
		);
	}



// VIEWLETS
	private string function sitePicker( event, rc, prc, struct args={} ) {
		var sites         = siteService.listSites();
		var currentSiteId = event.getSiteId();

		args.sites = [];
		args.currentSite = { id="" };

		for( var site in sites ){
			if ( hasCmsPermission( "sites.navigate", "site", [ site.id ] ) ) {
				if ( site.id == currentSiteId || ( IsEmpty( currentSiteId ) && sites.currentRow == 1 ) ) {
					args.currentSite = site;
				} else {
					args.sites.append( site );
				}

			}
		}

		return renderView( view="/admin/sites/sitePicker", args=args );
	}

// PRIVATE HELPERS
	private void function _checkPermissions( event ) {
		if ( !hasCmsPermission( "sites.manage" ) ) {
			event.adminAccessDenied();
		}
	}

	private void function _addRootBreadcrumb( event ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sites.manage.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="sites.manage" )
		);
	}
}