component output=false extends="preside.system.base.AdminHandler" {

	property name="siteService"     inject="siteService";
	property name="siteTreeService" inject="siteTreeService";
	property name="siteDao"         inject="presidecms:object:site";
	property name="aliasDao"        inject="presidecms:object:site_alias_domain";
	property name="redirectDao"     inject="presidecms:object:site_redirect_domain";
	property name="messagebox"      inject="coldbox:plugin:messagebox";

	public void function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "sites" ) ) {
			event.notFound();
		}
	}

	public void function manage( event, rc, prc ) output=false {
		_checkPermissions( event );
		_addRootBreadcrumb( event );

		prc.pageIcon     = "globe";
		prc.pageTitle    = translateResource( "cms:sites.manage.title" );
		prc.pageSubTitle = translateResource( "cms:sites.manage.subtitle" );
	}

	public void function addSite() output=false {
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

	public void function addSiteAction( event, rc, prc ) output=false {
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


	public void function editSite() output=false {
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

	public void function editSiteAction( event, rc, prc ) output=false {
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

	public void function editPermissions( event, rc, prc ) output=false {
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

	public void function saveSitePermissionsAction( event, rc, prc ) output=false {
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

	public void function setActiveSite( event, rc, prc ) output=false {
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

	public void function getSitesForAjaxDataTables( event, rc, prc ) output=false {
		_checkPermissions( event );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "site"
				, gridFields  = "name,domain,path"
				, actionsView = "/admin/sites/_sitesGridActions"
			}
		);
	}



// VIEWLETS
	private string function sitePicker( event, rc, prc, struct args={} ) output=false {
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
	private void function _checkPermissions( event ) output=false {
		if ( !hasCmsPermission( "sites.manage" ) ) {
			event.adminAccessDenied();
		}
	}

	private void function _addRootBreadcrumb( event ) output=false {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sites.manage.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="sites.manage" )
		);
	}
}