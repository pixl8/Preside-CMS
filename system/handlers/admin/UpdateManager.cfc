component extends="preside.system.base.AdminHandler" output=false {

	property name="updateManagerService" inject="updateManagerService";
	property name="messageBox"           inject="coldbox:plugin:messageBox";


// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "updateManager" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( permissionKey="updateManager.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:updateManager" )
			, link  = event.buildAdminLink( linkTo="updateManager" )
		);

		prc.pageIcon = "cloud-download";
	}

// EVENTS
	function index( event, rc, prc ) output=false {
		prc.pageTitle               = translateResource( "cms:updateManager" );
		prc.pageSubTitle            = translateResource( "cms:updateManager.subtitle" );
		prc.isGitClone              = updateManagerService.isGitClone();
		prc.currentVersion          = prc.isGitClone ? updateManagerService.getGitBranch() : updateManagerService.getCurrentVersion();
		prc.latestVersion           = updateManagerService.getLatestVersion();
		prc.downloadedVersions      = updateManagerService.listDownloadedVersions();
		prc.availableVersions       = updateManagerService.listAvailableVersions();
		prc.versionUpToDate         = prc.currentVersion >= prc.latestVersion.version;
		prc.latestVersionDownloaded = prc.versionUpToDate || updateManagerService.versionIsDownloaded( prc.latestVersion.version );
		prc.downloadingVersions     = updateManagerService.listDownloadingVersions();

		for( var version in prc.downloadingVersions ){
			if ( prc.downloadingVersions[ version ].complete ) {
				if ( prc.downloadingVersions[ version ].success ) {
					messagebox.info( translateResource( uri="cms:updateManager.download.complete.confirmation", data=[ version ] ) );
				} else {
					messagebox.error( translateResource( uri="cms:updateManager.download.error.message", data=[ version ] ) );
				}
				updateManagerService.clearDownload( version );
			}
		}

		event.setView( "/admin/updateManager/index" );
	}

	function editSettings( event, rc, prc ) output=false {
		prc.pageTitle    = translateResource( "cms:updateManager.editSettings" );
		prc.pageSubTitle = translateResource( "cms:updateManager.editSettings.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:updateManager.editSettings.breadCrumb" )
			, link  = event.buildAdminLink( linkTo="updateManager.editSettings" )
		);

		prc.settings = updateManagerService.getSettings();

		event.setView( "/admin/updateManager/editSettings" );

	}

	function editSettingsAction( event, rc, prc ) output=false {
		var formName         = "update-manager.general.settings";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;

			setNextEvent( url=event.buildAdminLink( linkTo="updateManager.editSettings" ), persistStruct=persist );
		}

		updateManagerService.saveSettings( settings=formData );

		messageBox.info( translateResource( uri="cms:updateManager.settings.saved.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );

	}

	function downloadVersionAction( event, rc, prc ) output=false {
		try {
			updateManagerService.downloadVersion( version = rc.version ?: "" );
		} catch( "UpdateManagerService.unknown.version" e ) {
			messageBox.error( translateResource( uri="cms:updatemanager.download.version.not.found.error", data=[ rc.version ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );

		}

		messageBox.info( translateResource( uri="cms:updatemanager.download.started.confirmation", data=[ rc.version ?: "" ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );
	}

	function installVersionAction( event, rc, prc ) output=true {
		try {
			updateManagerService.installVersion( version = rc.version ?: "" );
		} catch( "UpdateManagerService.unknown.version" e ) {
			messageBox.error( translateResource( uri="cms:updatemanager.install.version.not.found.error", data=[ rc.version ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );

		} catch( "UpdateManagerService.lucee.admin.secured" e ) {
			messageBox.error( translateResource( uri="cms:updatemanager.install.lucee.admin.access.denied", data=[ rc.version ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );

		} catch( "presidecms.auto.schema.sync.disabled" exception ) {
			var errorMessage = "";
			savecontent variable="errorMessage" {
				include template="/preside/system/views/errors/sqlRebuild.cfm";
			}
			header statuscode=500;content reset=true;WriteOutput( Trim( errorMessage ) );abort;
		}

		messageBox.info( translateResource( uri="cms:updatemanager.installed.confirmation", data=[ rc.version ?: "" ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );
	}

	function removeLocalVersionAction( event, rc, prc ) output=false {
		try {
			updateManagerService.deleteVersion( version = rc.version ?: "" );
		} catch( "UpdateManagerService.unknown.version" e ) {
			messageBox.error( translateResource( uri="cms:updatemanager.delete.version.not.found.error", data=[ rc.version ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );

		} catch( "UpdateManagerService.cannot.delete.current.version" e ) {
			messageBox.error( translateResource( uri="cms:updatemanager.cannot.delete.current.version.error", data=[ rc.version ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );

		} catch( "UpdateManagerService.failed.to.delete" e ) {
			messageBox.error( translateResource( uri="cms:updatemanager.cannot.delete.version.error", data=[ rc.version ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );
		}

		messageBox.info( translateResource( uri="cms:updatemanager.version.deleted.confirmation", data=[ rc.version ?: "" ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="updateManager" ) );
	}

	function downloadIsComplete( event, rc, prc ) output=false {
		event.renderData( data={ complete=updateManagerService.downloadIsComplete( rc.version ?: "" ) }, type="json" );
	}

}