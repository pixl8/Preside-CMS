component extends="preside.system.base.AdminHandler" {

	property name="assetManagerService"              inject="assetManagerService";
	property name="websitePermissionService"         inject="websitePermissionService";
	property name="formsService"                     inject="formsService";
	property name="presideObjectService"             inject="presideObjectService";
	property name="contentRendererService"           inject="contentRendererService";
	property name="imageManipulationService"         inject="imageManipulationService";
	property name="errorLogService"                  inject="errorLogService";
	property name="storageProviderService"           inject="storageProviderService";
	property name="storageLocationService"           inject="storageLocationService";
	property name="messageBox"                       inject="messagebox@cbmessagebox";
	property name="datatableHelper"                  inject="jQueryDatatablesHelpers";
	property name="multilingualPresideObjectService" inject="multilingualPresideObjectService";
	property name="assetQueueService"                inject="presidecms:dynamicservice:assetQueue";
	property name="derivativeLimits"                 inject="coldbox:setting:assetManager.derivativeLimits";

	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "assetManager" ) ) {
			event.notFound();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager" )
			, link  = event.buildAdminLink( linkTo="assetmanager" )
		);

		if ( Len( Trim( rc.asset ?: "" ) ) ) {
			prc.asset = assetManagerService.getAsset( rc.asset );
			if ( not prc.asset.recordCount ) {
				messageBox.error( translateResource( uri="cms:assetmanager.asset.not.found.error" ) );
				setNextEvent( url = event.buildAdminLink( linkTo="assetManager" ) );
			}
			prc.asset = QueryRowToStruct( prc.asset );
			rc.folder = prc.asset.asset_folder;
		}

		prc.rootFolderId = assetManagerService.getRootFolderId();
		if ( Len( Trim( rc.asset_folder ?: "" ) ) ) {
			rc.folder = rc.asset_folder;
		}
		if ( !Len( Trim( rc.folder ?: "" ) ) ) {
			rc.folder = prc.rootFolderId;
		}

		prc.folderAncestors   = assetManagerService.getFolderAncestors( id=rc.folder ?: "" );
		prc.permissionContext = [];
		prc.inheritedPermissionContext = [];

		for( var f in prc.folderAncestors ){
			prc.permissionContext.prepend( f.id );
			prc.inheritedPermissionContext.prepend( f.id );

			if ( f.id != prc.rootFolderId ) {
				event.addAdminBreadCrumb(
					  title = f.label
					, link  = event.buildAdminLink( linkTo="assetmanager", querystring="folder=#f.id#" )
				);
			}
		}

		prc.isTrashFolder = rc.folder == "trash";
		prc.folder        = assetManagerService.getFolder( id=rc.folder );

		if ( prc.folder.recordCount ){
			if ( prc.folder.id != assetManagerService.getRootFolderId() ) {
				event.addAdminBreadCrumb(
					  title = prc.folder.label
					, link  = event.buildAdminLink( linkTo="assetmanager", querystring="folder=#prc.folder.id#" )
				);
			}

			prc.permissionContext.prepend( rc.folder );
		}

		_checkPermissions( argumentCollection=arguments, key="general.navigate" );
	}

	function index( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="general.navigate" );

		prc.folderTree    = assetManagerService.getFolderTree();
		prc.trashCount    = assetManagerService.getTrashCount();
	}

	function trashAssetAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.delete" );

		var assetId          = rc.asset ?: "";
		var asset            = assetManagerService.getAsset( assetId );
		var parentFolder     = asset.recordCount ? asset.asset_folder : "";
		var alreadyTrashed   = IsTrue( asset.is_trashed );
		var trashed          = "";

		try {
			if ( alreadyTrashed ) {
				trashed = assetManagerService.permanentlyDeleteAsset( assetId );
			} else {
				trashed = assetManagerService.trashAsset( assetId );
			}
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.trash.asset.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", querystring="folder=#parentFolder#" ) );
		}

		if ( trashed ) {
			if ( alreadyTrashed ) {
				messageBox.info( translateResource( uri="cms:assetmanager.delete.asset.success", data=[ asset.original_title ] ) );
			} else {
				messageBox.info( translateResource( uri="cms:assetmanager.trash.asset.success", data=[ asset.title ] ) );
			}
		} else {
			messageBox.error( translateResource( "cms:assetmanager.trash.asset.unexpected.error" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#parentFolder#" ) );
	}

	function clearAssetDerivativesAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var assetId = rc.asset ?: "";

		try {
			assetManagerService.clearAssetDerivatives( assetId );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.clear.derivatives.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#assetId#" ) );
		}

		messageBox.info( translateResource( "cms:assetmanager.clear.derivatives.success" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#assetId#" ) );
	}

	function clearMultiAssetsDerivativesAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var assetIds = listToArray( rc.id ?: "" );

		try {
			assetManagerService.clearAssetDerivatives( assetIds );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.clear.derivatives.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager" ) );
		}

		messageBox.info( translateResource( "cms:assetmanager.clear.derivatives.success" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager" ) );
	}

	function clearFolderDerivativesAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var folderId = rc.folder ?: "";

		try {
			assetManagerService.clearFolderDerivatives( folderId );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.clear.derivatives.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager" ) );
		}

		messageBox.info( translateResource( "cms:assetmanager.clear.derivatives.success" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager" ) );
	}

	function multiRecordAction( event, rc, prc ) {
		// TODO: permissions checks, etc.
		var action = rc.multiAction ?: ""
		var ids    = rc.id          ?: ""

		if ( not Len( Trim( ids ) ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager" ) );
		}

		switch( action ){
			case "delete":
				return trashMultiAssetsAction( argumentCollection = arguments );
			case "clearDerivatives":
				return clearMultiAssetsDerivativesAction( argumentCollection = arguments );
			break;
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager" ) );
	}

	function trashMultiAssetsAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.delete" );
		var parentFolder = "";
		var permanent    = false;

		for( var assetId in ListToArray( rc.id ?: "" ) ) {
			var asset = assetManagerService.getAsset( assetId );
			parentFolder = asset.recordCount ? asset.asset_folder : "";

			var alreadyTrashed = IsTrue( asset.is_trashed );
			if ( alreadyTrashed ) {
				permanent = true;
			}

			try {
				if ( alreadyTrashed ) {
					assetManagerService.permanentlyDeleteAsset( assetId );
				} else {
					assetManagerService.trashAsset( assetId );
				}
			} catch ( any e ) {
				logError( e );
				messageBox.error( translateResource( "cms:assetmanager.trash.asset.unexpected.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="assetManager", querystring="folder=#parentFolder#" ) );
			}
		}

		if ( permanent ) {
			messageBox.info( translateResource( uri="cms:assetmanager.delete.assets.success" ) );
		} else {
			messageBox.info( translateResource( uri="cms:assetmanager.trash.assets.success" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#parentFolder#" ) );
	}

	function moveAssetsAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var assetIds      = ListToArray( rc.assets ?: "" );
		var folderId      = rc.toFolder   ?: "";
		var fromFolder    = rc.fromFolder ?: "";

		if ( assetIds.len() ) {
			if ( !Len( Trim( fromFolder ) ) ) {
				var asset = assetmanagerService.getAsset( assetIds[1] );
				fromFolder = asset.asset_folder ?: "";
			}
			var success = true;
			try {
				assetManagerService.moveAssets(
					  assetIds  = assetIds
					, folderId  = folderId
				);
			} catch( "PresideCMS.AssetManager.asset.wrong.type.for.folder" e ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.to.folder.error" ) );
				success = false;
			} catch( "PresideCMS.AssetManager.asset.too.big.for.folder" e ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.to.folder.error" ) );
				success = false;
			} catch( "PresideCMS.AssetManager.folder.in.different.location" e ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.across.locations.error" ) );
				success = false;
			} catch ("PresideCMS.AssetManager.asset.file.exist.in.folder" e ){
				messagebox.error( translateResource( "cms:assetmanager.assets.file.is.exist.in.folder.error" ) );
				success = false;
			}

			if ( !success ) {
				setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=" & fromFolder ) );
			}
		}

		messagebox.info( translateResource( "cms:assetmanager.assets.moved.confirmation" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=" & fromFolder ) );
	}

	function restoreAssetsAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var assetIds      = ListToArray( rc.assets ?: "" );
		var folderId      = rc.toFolder   ?: "";

		if ( assetIds.len() ) {
			var success = true;
			try {
				assetManagerService.restoreAssets(
					  assetIds  = assetIds
					, folderId  = folderId
				);
			} catch( "PresideCMS.AssetManager.asset.wrong.type.for.folder" e ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.to.folder.error" ) );
				success = false;
			} catch( "PresideCMS.AssetManager.asset.too.big.for.folder" e ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.to.folder.error" ) );
				success = false;
			} catch( "PresideCMS.AssetManager.folder.in.different.location" e ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.across.locations.error" ) );
				success = false;
			}

			if ( !success ) {
				setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=" & fromFolder ) );
			}
		}

		messagebox.info( translateResource( "cms:assetmanager.assets.restored.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=trash" ) );
	}

	function addFolder( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="folders.add" );
	}

	function addFolderAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="folders.add" );

		var formName         = "preside-objects.asset_folder.admin.add";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = "";
		var newFolderId      = "";

		formData.parent_folder = rc.folder ?: "";
		formData.created_by = formData.updated_by = event.getAdminUserId();

		validationResult = validateForm(
			  formName = formName
			, formData = formData
		);

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:assetmanager.add.folder.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.addFolder", querystring="folder=#formData.parent_folder#" ), persistStruct=persist );
		}

		try {
			newFolderId = assetManagerService.addFolder( argumentCollection = formData );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.add.folder.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.addFolder", querystring="folder=#formData.parent_folder#" ), persistStruct=formData );
		}

		websitePermissionService.syncContextPermissions(
			  context       = "asset"
			, contextKey    = newFolderId
			, permissionKey = "assets.access"
			, grantBenefits = ListToArray( rc.grant_access_to_benefits ?: "" )
			, denyBenefits  = ListToArray( rc.deny_access_to_benefits  ?: "" )
			, grantUsers    = ListToArray( rc.grant_access_to_users    ?: "" )
			, denyUsers     = ListToArray( rc.deny_access_to_users     ?: "" )
		);

		messageBox.info( translateResource( uri="cms:assetmanager.folder.added.confirmation", data=[ formData.label ?: '' ] ) );
		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.addFolder", queryString="folder=#formData.parent_folder#" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#newFolderId#" ) );
		}
	}

	function editFolder( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="folders.edit" );

		prc.record = prc.folder ?: QueryNew('');
		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:assetmanager.folderNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.index" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		var contextualAccessPerms = websitePermissionService.getContextualPermissions(
			  context       = "asset"
			, contextKey    = prc.record.id
			, permissionKey = "assets.access"
		);
		prc.record.grant_access_to_benefits = ArrayToList( contextualAccessPerms.benefit.grant );
		prc.record.deny_access_to_benefits  = ArrayToList( contextualAccessPerms.benefit.deny );
		prc.record.grant_access_to_users    = ArrayToList( contextualAccessPerms.user.grant );
		prc.record.deny_access_to_users     = ArrayToList( contextualAccessPerms.user.deny );
	}

	function editFolderAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="folders.edit" );

		var folderId          = ( rc.id ?: "" );
		var formName          = folderId == prc.rootFolderId ? formsService.getMergedFormName( "preside-objects.asset_folder.admin.edit", "preside-objects.asset_folder.admin.edit.root" ) : "preside-objects.asset_folder.admin.edit";
		var formData          = event.getCollectionForForm( formName );
		var validationResult  = "";

		formData.id            = folderId;
		formData.updated_by    = event.getAdminUserId();

		validationResult = validateForm(
			  formName = formName
			, formData = formData
		);

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:assetmanager.edit.folder.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editFolder", querystring="folder=#parentFolder#&id=#folderId#" ), persistStruct=persist );
		}

		try {
			assetManagerService.editFolder( id=folderId, data=formData );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.edit.folder.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editFolder", querystring="folder=#parentFolder#&id=#folderId#" ), persistStruct=formData );
		}

		websitePermissionService.syncContextPermissions(
			  context       = "asset"
			, contextKey    = folderId
			, permissionKey = "assets.access"
			, grantBenefits = ListToArray( rc.grant_access_to_benefits ?: "" )
			, denyBenefits  = ListToArray( rc.deny_access_to_benefits  ?: "" )
			, grantUsers    = ListToArray( rc.grant_access_to_users    ?: "" )
			, denyUsers     = ListToArray( rc.deny_access_to_users     ?: "" )
		);

		messageBox.info( translateResource( uri="cms:assetmanager.folder.edited.confirmation", data=[ prc.folder.label ?: '' ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#folderId#" ) );
	}

	function setFolderLocation( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		prc.record = prc.folder ?: QueryNew('');
		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:assetmanager.folderNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.index" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		prc.pageIcon     = "picture-o";
		prc.pageTitle    = translateResource( uri="cms:assetManager.set.folder.location.title", data=[ prc.record.label ] );
		prc.pageSubTitle = translateResource( uri="cms:assetManager.set.folder.location.subtitle", data=[ prc.record.label ] );
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager.set.folder.crumbtrail.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.setFolderLocation", queryString="folder=#( rc.folder ?: '' )#" )
		);
	}

	function setFolderLocationAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		var folderId          = ( rc.folder ?: "" );
		var formName          = "preside-objects.asset_folder.admin.setlocation"
		var formData          = event.getCollectionForForm( formName );
		var validationResult  = "";

		formData.id            = folderId;
		formData.updated_by    = event.getAdminUserId();

		validationResult = validateForm(
			  formName = formName
			, formData = formData
		);

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:assetmanager.edit.folder.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.setfolderlocation", querystring="folder=#parentFolder#&id=#folderId#" ), persistStruct=persist );
		}

		try {
			assetManagerService.setFolderLocation( id=folderId, data=formData );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.edit.folder.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.setfolderlocation", querystring="folder=#parentFolder#&id=#folderId#" ), persistStruct=formData );
		}

		messageBox.info( translateResource( uri="cms:assetmanager.folder.location.set.confirmation", data=[ prc.folder.label ?: '' ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#folderId#" ) );
	}

	function trashFolderAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="folders.delete" );

		var folderId         = rc.folder ?: "";

		if ( assetManagerService.folderHasContent( folderId ) ) {
			messageBox.warn( translateResource( "cms:assetmanager.trash.folder.not.empty.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", querystring="folder=#folderId#" ) );
		}

		var folder           = assetManagerService.getFolder( folderId );
		var parentFolder     = folder.recordCount ? folder.parent_folder : "";
		var trashed          = "";

		try {
			trashed = assetManagerService.trashFolder( folderId );
		} catch ( any e ) {
			logError( e );
			messageBox.error( translateResource( "cms:assetmanager.trash.folder.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", querystring="folder=#parentFolder#" ) );
		}

		if ( trashed ) {
			messageBox.info( translateResource( uri="cms:assetmanager.trash.folder.success", data=[ folder.label ] ) );
		} else {
			messageBox.error( translateResource( "cms:assetmanager.trash.folder.unexpected.error" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#parentFolder#" ) );
	}

	function uploadAssets( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var folderId = rc.folder  ?: "";
		var folder   = prc.folder ?: queryNew("");
		if( folder.recordCount ){
			var maxFileSize   = folder.max_filesize_in_mb ?: 100;
			var allowedTypes  = folder.allowed_filetypes  ?: "";
			var extensionList = "";

			assetManagerService.expandTypeList( ListToArray( allowedTypes ) ).each( function( type ){
				extensionList = ListAppend( extensionList, ".#type#" );
			} );

			event.includeData( { allowedExtensions = extensionList, maxFileSize = maxFileSize } );
		}

		prc.pageIcon     = "picture";
		prc.pageTitle    = translateResource( "cms:assetManager" );
		prc.pageSubTitle = translateResource( "cms:assetmanager.upload.assets.title" );

		event.addAdminBreadCrumb(
			  title = prc.pageSubTitle
			, link  = event.buildAdminLink( linkTo="assetmanager.uploadAssets", queryString="folder=#folderId#" )
		);
	}

	function uploadAssetAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		rc.file = runEvent(
			  event          = "preprocessors.FileUpload.index"
			, eventArguments = { fieldName="file" }
			, private        = true
			, prePostExempt  = true
		);
		var imageExtensions = [ "png", "gif", "jpg", "jpeg", "jpe", "jif", "jfif", "jfi" ];
		var tempFileInfo    = rc.file.tempFileInfo ?: {};
		var fileExtension   = ListLast( tempFileInfo.serverFile, "." );
		var result          = { success=true, message="",  id="" };
		var fileName        = tempFileInfo.clientFile ?: "";

		if ( !Len( Trim( fileName ) ) ) {
			result.success = false;
			result.message = translateResource( "cms:assetmanager.file.upload.error.missing.file" );
		} else if ( !Len( Trim( rc.asset_folder ?: "" ) ) ) {
			result.success = false;
			result.message = translateResource( "cms:assetmanager.file.upload.error.missing.folder" );
		} else if( imageExtensions.findNoCase( fileExtension ) && ( !imageManipulationService.isValidImageFile( tempFileInfo.serverDirectory & "/" & tempFileInfo.serverFile ) ) ) {
			result.success = false;
			result.message = translateResource( "cms:assetmanager.uploader.image.format.failure" );
		} else {
			var assetData = event.getCollectionWithoutSystemVars();

			assetData.delete( "asset_folder" );
			assetData.delete( "file" );

			var convertTiffs = IsTrue( getSystemSetting( category="asset-manager", setting="tiff_conversion", default=false ) );

			if ( ListFindNoCase( "tif,tiff", ListLast( assetData.title, "." ) ) && convertTiffs ) {
				assetData.title = Len( Trim( assetData.title ?: "" ) ) ? ReplaceNoCase( assetData.title, ListLast( assetData.title, "." ), "jpg" ) : fileName;
			} else {
				assetData.title = Len( Trim( assetData.title ?: "" ) ) ? assetData.title : fileName;
			}

			try {
				var assetId = assetManagerService.addAsset(
					  fileBinary        = rc.file.binary
					, folder            = rc.asset_folder ?: ""
					, fileName          = filename
					, assetData         = assetData
					, ensureUniqueTitle = true
				);
				var assetEditUrl = event.buildAdminLink( linkto="assetmanager.editasset", queryString="asset=" & assetId );
				var editLink     = '<a href="#assetEditUrl#" target="_blank"><i class="fa fa-fw fa-external-link"></i> #assetData.title#</a>';

				result.id      = assetId;
				result.message = editLink;
			} catch ( "assetManager.fileTypeNotFound" e ) {
				result.success = false;
				result.message = translateResource( uri="cms:assetmanager.uploader.messages.invalidFileType", data=[ fileExtension ] );

			} catch ( any e ) {

				if ( ReFindNoCase( "^PresideCMS\.AssetManager", e.type ?: "" ) ) {
					result.success = false;
					result.message = translateResource( ReReplace( e.type, "^PresideCMS\.", "cms:" ) );
				} else {
					logError( e );
					rethrow;
				}
			}
		}

		event.renderData( data=result, type="json" );
	}

	function editAsset( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var contextualAccessPerms = websitePermissionService.getContextualPermissions(
			  context       = "asset"
			, contextKey    = rc.asset
			, permissionKey = "assets.access"
		);
		prc.asset.grant_access_to_benefits = ArrayToList( contextualAccessPerms.benefit.grant );
		prc.asset.deny_access_to_benefits  = ArrayToList( contextualAccessPerms.benefit.deny );
		prc.asset.grant_access_to_users    = ArrayToList( contextualAccessPerms.user.grant );
		prc.asset.deny_access_to_users     = ArrayToList( contextualAccessPerms.user.deny );

		event.include( "/js/admin/specific/owlcarousel/"  )
		     .include( "/css/admin/specific/owlcarousel/" );

		prc.versions     = assetManagerService.getAssetVersions( rc.asset );
		prc.assetType    = assetManagerService.getAssetType( name=prc.asset.asset_type );
		prc.isImageAsset = listFirst( prc.assetType.mimetype, "/" ) == "image";

		prc.isMultilingual = multilingualPresideObjectService.isMultilingual( "asset" );
		prc.canTranslate   = prc.isMultilingual && hasCmsPermission( permissionKey="assetmanager.assets.translate" , context="assetmanagerfolder", contextKeys= prc.permissionContext );

		if ( prc.canTranslate ) {
			prc.assetTranslations = multilingualPresideObjectService.getTranslationStatus( "asset", rc.asset );
		}

		if ( isFeatureEnabled( "assetQueue" ) && hasCmsPermission( "assetmanager.failedDerivatives" ) ) {
			prc.latestFailedQueueItem = assetQueueService.getFailedItems( assetId=rc.asset, maxRows=1 );
		}

		prc.tooLargeForDerivatives = assetManagerService.assetIsTooLargeForDerivatives( prc.asset.width, prc.asset.height );
		if ( prc.tooLargeForDerivatives ) {
			prc.tooLargeMessage = _getAssetTooLargeMessage( argumentCollection=arguments );
		}
	}

	function editAssetAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var assetId          = rc.asset  ?: "";
		var folderId         = rc.folder ?: "";
		var formName         = StructKeyExists( rc, "focal_point" ) ? formsService.getMergedFormName( "preside-objects.asset.admin.edit", "preside-objects.asset.cropping" ) : "preside-objects.asset.admin.edit";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = "";
		var success          = true;
		var persist          = {};

		formData.id = assetId;
		if ( not Len( Trim( formData.asset_folder ?: "" ) ) ) {
			formData.asset_folder = folderId;
		}
		validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=#assetId#" ), persistStruct=persist );
		}

		try {
			success = assetManagerService.editAsset( id=rc.asset ?: "", data=formData );
		} catch( any e ) {
			logError( e );
			success = false;
		}

		if ( success ) {
			websitePermissionService.syncContextPermissions(
				  context       = "asset"
				, contextKey    = assetId
				, permissionKey = "assets.access"
				, grantBenefits = ListToArray( rc.grant_access_to_benefits ?: "" )
				, denyBenefits  = ListToArray( rc.deny_access_to_benefits  ?: "" )
				, grantUsers    = ListToArray( rc.grant_access_to_users    ?: "" )
				, denyUsers     = ListToArray( rc.deny_access_to_users     ?: "" )
			);

			messagebox.info( translateResource( uri="cms:assetmanager.asset.edit.success", data=[ formData.title ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#folderId#" ) );
		} else {
			messagebox.error( translateResource( "cms:assetmanager.asset.edit.unexpected.error" ) );
			persist = formData;
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=#assetId#" ), persistStruct=persist );
		}
	}

	function dismissQueueErrorsAction( event, rc, prc ) {
		if ( !isFeatureEnabled( "assetQueue" ) || !hasCmsPermission( "assetmanager.failedDerivatives" ) ) {
			event.adminAccessDenied();
		}

		var assetId = rc.id ?: "";

		assetQueueService.dismissFailedItems( assetId=assetId );

		messagebox.info( translateResource( uri="cms:assetmanager.generated.asset.dismissed.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#assetId#" ) );

	}

	function translateAssetRecord( event, rc, prc ) {
		var object                = rc.object ?: "";
		var id                    = rc.id     ?: "";
		var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( object );
		var record                = "";
		prc.language              = multilingualPresideObjectService.getLanguage( rc.language ?: "" );

		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:assetManager.translation.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#id#" ) );
		}
		_checkPermissions( argumentCollection=arguments, key="assets.translate" );

		prc.sourceRecord = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
		prc.record       = multiLingualPresideObjectService.selectTranslation( objectName=object, id=id, languageId=prc.language.id, useCache=false );

		if ( not prc.sourceRecord.recordCount ) {
			messageBox.error( translateResource( uri="cms:assetManager.translation.recordNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", querystring="asset=#id#" ) );
		}
		prc.record       = queryRowToStruct( prc.record );
		prc.recordLabel  = prc.sourceRecord[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield",  defaultValue="label" ) ] ?: "";
		prc.translations = multilingualPresideObjectService.getTranslationStatus( object, id );
		prc.formName     = "preside-objects.#translationObjectName#.admin.edit";

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:assetManager.translaterecord.breadcrumb.title", data=[ prc.language.name ] )
			, link  = ""
		);
		prc.pageIcon  = "pencil";
		prc.pageTitle = translateResource( uri="cms:assetManager.translaterecord.title", data=[ prc.recordLabel, prc.language.name ] );
	}
	function translateAssetRecordAction( event, rc, prc ) {
		var id                    = rc.id       ?: "";
		var object                = rc.object   ?: "";
		var languageId            = rc.language ?: "";
		var persist               = "";
		var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( object );

		_checkPermissions( argumentCollection=arguments, key="assets.translate" );
		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );

		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:assetManager.translation.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#id#" ) );
		}

		if ( not presideObjectService.dataExists( objectName=object, filter={ id=id } ) ) {
			messageBox.error( translateResource( uri="cms:assetManager.translation.recordNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#id#" ) );
		}

		var formName         = "preside-objects.#translationObjectName#.admin.edit";
		var formData         = event.getCollectionForForm( formName );
		var existingTranslation = multilingualPresideObjectService.selectTranslation(
			  objectName   = object
			, id           = id
			, languageId   = languageId
			, selectFields = [ "id" ]
		);

		formData._translation_language = languageId;
		if ( existingTranslation.recordCount ) {
			formData.id = existingTranslation.id;
		}
		var validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:assetManager.translation.validation.error" ) );
			persist                  = formData;
			persist.validationResult = validationResult;
			persist.delete( "id" );

			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", querystring="object=#object#&id=#id#&language=#languageId#" ), persistStruct=persist );
		}

		formData._translation_active = IsTrue( rc._translation_active ?: "" );
		multilingualPresideObjectService.saveTranslation(
			  objectName = object
			, id         = id
			, data       = formData
			, languageId = languageId
		);

		messageBox.info( translateResource( uri="cms:assetManager.recordTranslated.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editAsset", querystring="asset=#id#" ) );
	}

	function makeVersionActiveAction( event, rc, prc ) {
		var success = assetManagerService.makeVersionActive(
			  assetId   = ( rc.asset   ?: "" )
			, versionId = ( rc.version ?: "" )
		);

		if ( success ) {
			messagebox.info( translateResource( "cms:assetmanager.asset.make.version.active.success" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#rc.asset#" ) );
	}

	function deleteAssetVersionAction( event, rc, prc ) {
		var success = assetManagerService.deleteAssetVersion(
			  assetId   = ( rc.asset   ?: "" )
			, versionId = ( rc.version ?: "" )
		);

		if ( success ) {
			messagebox.info( translateResource( "cms:assetmanager.asset.delete.version.success" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager.editAsset", queryString="asset=#rc.asset#" ) );
	}

	function uploadNewVersionAction( event, rc, prc ) {
		var assetId  = rc.asset ?: "";

		if ( !Len( Trim( assetId ) ) ) {
			event.notFound();
		}

		var formName = "preside-objects.asset.newversion";
		var formData = event.getCollectionForForm( formName );

		preProcessForm( formName, formData );

		if ( !IsStruct( formData.file ?: "" ) || formData.file.isEmpty() ) {
			messagebox.error( translateResource( "cms:assetmanager.upload.new.version.missing.file" ) );
		} else {
			var success = false;

			try {
				success = assetmanagerService.addAssetVersion(
					  assetId    = assetId
					, fileBinary = formData.file.binary
					, fileName   = formData.file.fileName
				);
			} catch ( "AssetManager.mismatchedMimeType" e ) {
				messagebox.error( translateResource( "cms:assetmanager.upload.new.version.mismatched.type.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=" & assetId ) )

			} catch ( any e ) {
				success = false;
				errorLogService.raiseError( e );
			}

			if ( success ) {
				messagebox.info( translateResource( "cms:assetmanager.upload.new.version.confirmation" ) );
			} else {
				messagebox.error( translateResource( "cms:assetmanager.upload.new.version.unknown.error" ) );
			}
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=" & assetId ) )
	}

	function assetPickerBrowser( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.pick" );

		var allowedTypes = rc.allowedTypes ?: "";
		var multiple     = rc.multiple     ?: "";

		prc.savedFilters = rc.savedFilters ?: "";
		prc.allowedTypes = assetManagerService.expandTypeList( ListToArray( allowedTypes ) );

		event.setLayout( "adminModalDialog" );

		prc._adminBreadCrumbs = [];
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:home.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="allowedTypes=#allowedTypes#&savedFilters=#prc.savedFilters#" )
		);
		if ( Len( Trim( rc.folder ?: "" ) ) ) {
			prc.folderAncestors = assetManagerService.getFolderAncestors( id=rc.folder );
			for( var f in prc.folderAncestors ){
				event.addAdminBreadCrumb(
					  title = f.label
					, link  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="folder=#f.id#&allowedTypes=#allowedTypes#&savedFilters=#prc.savedFilters#&multiple=#multiple#" )
				);
			}

			prc.folder = assetManagerService.getFolder( id=rc.folder );
			if ( prc.folder.recordCount ){
				event.addAdminBreadCrumb(
					  title = prc.folder.label
					, link  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="folder=#prc.folder.id#&allowedTypes=#allowedTypes#&savedFilters=#prc.savedFilters#&multiple=#multiple#" )
				);
			}
		}
	}

	function assetPickerUploader( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var multiple       = rc.multiple     ?: "";
		var allowedTypes   = rc.allowedTypes ?: "";
		var maxFileSize    = rc.maxFileSize  ?: "";

		if ( Len( Trim( allowedTypes ) ) ) {
			var extensionList = "";
			assetManagerService.expandTypeList( ListToArray( allowedTypes ) ).each( function( type ){
				extensionList = ListAppend( extensionList, ".#type#" );
			} );
			event.includeData( { allowedExtensions = extensionList, maxFileSize = maxFileSize } );
		}

		if ( !IsBoolean( multiple ) || !multiple ) {
			event.includeData( { maxFiles = 1 } );
		}

		prc.uploadCompleteView = '/admin/assetmanager/_batchUploadCompleteMessagingForAssetPicker';

		event.setLayout( "adminModalDialog" );
		event.setView( "admin/assetmanager/uploadAssets" );
	}

	function ajaxSearchAssets( event, rc, prc ) {
		var records = assetManagerService.searchAssets(
			  maxRows      = rc.maxRows      ?: 100
			, searchQuery  = rc.q            ?: ""
			, savedFilters = rc.savedFilters ?: ""
			, ids          = ListToArray( rc.values       ?: "" )
			, allowedTypes = ListToArray( rc.allowedTypes ?: "" )
		);

		var rootFolderName   = translateResource( "cms:assetmanager.root.folder" );
		var processedRecords = [];

		for( var record in records ) {
			record.icon        = renderAsset( record.value, "pickerIcon" );

			if ( Val( record.width ) && Val( record.height ) ) {
				record.largerImage = event.buildLink( assetId=record.value, derivative='adminThumbnail' );
				record.dimension =  "(" & record.width & "x" & record.height & ")";
			} else {
				record.largerImage = "";
				record.dimension =  "";
			}

			if ( record.folder == "$root" ) {
				record.folder = rootFolderName;
			}

			processedRecords.append( record );
		}

		event.renderData( type="json", data=processedRecords );
	}

	function getFoldersForAjaxSelectControl( event, rc, prc ) {
		var records = assetManagerService.getFoldersForSelectList(
			  maxRows             = rc.maxRows ?: 100
			, searchQuery         = rc.q       ?: ""
			, ids                 = ListToArray( rc.values ?: "" )
			, excludeDescendants  = rc.excludeDescendants  ?: ""
		);

		event.renderData( type="json", data=records );
	}

	function assetsForListingGrid( event, rc, prc ) {
		if ( prc.isTrashFolder ) {
			runEvent( event="admin.assetManager.trashedAssetsForListingGrid" );
			return;
		}

		var result = assetManagerService.getAssetsForGridListing(
			  startRow    = datatableHelper.getStartRow()
			, maxRows     = datatableHelper.getMaxRows()
			, orderBy     = datatableHelper.getSortOrder()
			, searchQuery = datatableHelper.getSearchQuery()
			, folder      = rc.folder ?: ""
		);
		var gridFields = [ "title", "datemodified", "datecreated" ];
		var renderedOptions = [];
		var checkboxCol     = []

		var records = Duplicate( result.records );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( "asset", field, record[ field ], [ "adminDataTable", "admin" ] );
				if ( field == "title" ) {
					records[ field ][ records.currentRow ] = '<span class="asset-preview">' & renderAsset( assetId=record.id, context="pickericon" ) & "</span> <span class='asset-title'>" & records[ field ][ records.currentRow ] & "</span>";
				}
			}

			checkboxCol.append( renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
			if ( IsTrue( rc.isTrashFolder ?: "" ) ) {
				renderedOptions.append( renderView( view="/admin/assetmanager/_trashedAssetGridActions", args=record ) );
			} else {
				renderedOptions.append( renderView( view="/admin/assetmanager/_assetGridActions", args=record ) );
			}
		}

		QueryAddColumn( records, "_options" , renderedOptions );
		QueryAddColumn( records, "_checkbox", checkboxCol );
		gridFields.prepend( "_checkbox" );
		gridFields.append( "_options" );
		event.renderData( type="json", data=datatableHelper.queryToResult( records, gridFields, result.totalRecords ) );
	}

	function trashedAssetsForListingGrid( event, rc, prc ) {
		var result = assetManagerService.getAssetsForGridListing(
			  startRow    = datatableHelper.getStartRow()
			, maxRows     = datatableHelper.getMaxRows()
			, orderBy     = datatableHelper.getSortOrder()
			, searchQuery = datatableHelper.getSearchQuery()
			, trashed     = true
		);

		var gridFields = [ "title", "datemodified", "datecreated" ];
		var renderedOptions = [];
		var checkboxCol     = []

		var records = Duplicate( result.records );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( "asset", field, record[ field ], [ "adminDataTable", "admin" ] );
				if ( field == "title" ) {
					var type = assetManagerService.getAssetType( name=record.asset_type );
					if ( ( type.groupName ?: "" ) == "image" ) {
						records[ field ][ records.currentRow ] = '<span class="asset-preview"><img class="lazy" src="#event.buildLink( assetId=record.id, trashed=true )#"></span> <span class="asset-title">' & records[ field ][ records.currentRow ] & "</span>";
					} else {
						records[ field ][ records.currentRow ] = '<span class="asset-preview">' & renderAsset( assetId=record.id, context="pickerIcon" ) & '</span> <span class="asset-title">' & records[ field ][ records.currentRow ] & "</span>";
					}
				}
			}

			checkboxCol.append( renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
			renderedOptions.append( renderView( view="/admin/assetmanager/_trashedAssetGridActions", args=record ) );
		}

		QueryAddColumn( records, "_options" , renderedOptions );
		QueryAddColumn( records, "_checkbox", checkboxCol );
		gridFields.prepend( "_checkbox" );
		gridFields.append( "_options" );

		event.renderData( type="json", data=datatableHelper.queryToResult( records, gridFields, result.totalRecords ) );
	}

	function getFolderTitleAndActions( event, rc, prc ) {
		var data = { title="", multiActions="" };

		if ( !prc.isTrashFolder && Len( Trim( rc.folder ?: "" ) ) && prc.folder.recordCount ) {
			var isSystemFolder = IsTrue( prc.folder.is_system_folder ?: "" );

			data.title = renderView( view="admin/assetmanager/_folderTitleAndActions", args={ folderId=rc.folder, folderTitle=prc.folder.label, isSystemFolder=isSystemFolder } );
		}
		data.multiActions = renderView( view="admin/assetmanager/_listingTableMultiActions" );

		event.renderData( data=data, type="json" );
	}

	public void function pickerForEditorDialog( event, rc, prc ) {
		var jsonConfig = rc.configJson ?: "";

		if ( Len( Trim( jsonConfig ) ) ) {
			try {
				rc.append( DeSerializeJson( UrlDecode( jsonConfig ) ) );
			} catch ( any e ){
				logError( e );
			}

		}


		event.setLayout( "adminModalDialog" );
		event.setView( "admin/assetManager/pickerForEditorDialog" );
	}

	public void function getImageDetailsForCKEditorImageDialog( event, rc, prc ) {
		var assetId = rc.asset ?: "";
		var asset   = assetManagerService.getAsset( assetId );
		var binary  = assetManagerService.getAssetBinary( assetId );

		if ( asset.recordCount ) {
			asset = QueryRowToStruct( asset );

			if ( !IsNull( local.binary ) ) {
				asset.append( imageManipulationService.getImageInformation( binary ) );
				StructDelete( asset, "metadata" );
				StructDelete( asset, "colormodel" );
			}

			event.renderData( data=asset, type="json" );
		} else {
			event.renderData( data={}, type="json" );
		}
	}

	public void function getAttachmentDetailsForCKEditorDialog( event, rc, prc ) {
		var assetId = rc.asset ?: "";
		var asset   = assetManagerService.getAsset( assetId );

		if ( asset.recordCount ) {
			asset = QueryRowToStruct( asset );
			event.renderData( data=asset, type="json" );
		} else {
			event.renderData( data={}, type="json" );
		}
	}

	public void function renderEmbeddedImageForEditor( event, rc, prc ) {
		var richContent = rc.embeddedImage ?: "";
		var rendered    = contentRendererService.renderEmbeddedImages( richContent );

		event.renderData( data=rendered );
	}

	public void function renderEmbeddedAttachmentForEditor( event, rc, prc ) {
		var richContent = rc.embeddedAttachment ?: "";
		var rendered    = contentRendererService.renderEmbeddedAttachments( richContent );

		event.renderData( data=rendered );
	}

	public void function managePerms( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="folders.manageContextPerms" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:assetmanager.managePerms.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function savePermsAction( event, rc, prc ) {
		var folderId = rc.folder ?: "";
		var folderRecord = prc.folder ?: QueryNew( 'label' );

		_checkPermissions( argumentCollection=arguments, key="folders.manageContextPerms" );

		if ( runEvent( event="admin.Permissions.saveContextPermsAction", private=true ) ) {
			event.audit(
				  action   = "edit_asset_folder_admin_permissions"
				, type     = "assetmanager"
				, detail   = QueryRowToStruct( folderRecord )
				, recordId = folderId
			);
			messageBox.info( translateResource( uri="cms:assetmanager.permsSaved.confirmation", data=[ folderRecord.label ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.index", queryString="folder=#folderId#" ) );
		}

		messageBox.error( translateResource( uri="cms:assetmanager.permsSaved.error", data=[ folderRecord.label ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managePerms", queryString="folder=#folderId#" ) );
	}

	function manageLocations( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager.managelocations.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.managelocations" )
		);
		prc.pageIcon     = "picture-o";
		prc.pageTitle    = translateResource( "cms:assetManager.managelocations.page.title"    );
		prc.pageSubTitle = translateResource( "cms:assetManager.managelocations.page.subtitle" );
	}

	function getStorageLocationsForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "asset_storage_location"
				, useMultiActions = false
				, gridFields      = "name,storageProvider,datemodified"
				, actionsView     = "admin.assetmanager.locationGridActions"
			}
		);
	}

	function addLocation( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		var provider = rc.provider ?: "filesystem";

		prc.providerTitle    = translateResource( "storage-providers.#provider#:title" );
		prc.formName         = formsService.getMergedFormName( "preside-objects.asset_storage_location.admin.add", "storage-providers.#provider#" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager.managelocations.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.managelocations" )
		);

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager.addlocation.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.addlocation", queryString="provider=#provider#" )
		);

		prc.pageIcon     = "picture-o";
		prc.pageTitle    = translateResource( uri="cms:assetManager.addlocation.page.title"   , data=[ prc.providerTitle ] );
		prc.pageSubTitle = translateResource( uri="cms:assetManager.addlocation.page.subtitle", data=[ prc.providerTitle ] );
	}

	function addLocationAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		var provider         = rc.provider ?: "filesystem";
		var generalFormName  = "preside-objects.asset_storage_location.admin.add";
		var generalFormData  = event.getCollectionForForm( generalFormName );
		var providerFormName = "storage-providers.#provider#";
		var providerFormData = event.getCollectionForForm( providerFormName );
		var completeFormName = formsService.getMergedFormName( generalFormName, providerFormName );
		var completeFormData = event.getCollectionForForm( completeFormName );
		var validationResult = validateForm( completeFormName, completeFormData );

		storageProviderService.validateProvider(
			  id               = provider
			, configuration    = providerFormData
			, validationResult = validationResult
		);

		if ( !validationResult.validated() ) {
			var persist = completeFormData;
			persist.validationResult = validationResult;

			messageBox.error( translateResource( uri="cms:assetmanager.location.not.valid" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.addlocation", queryString="provider=" & provider ), persistStruct=persist );
		}

		var locationArgs = {
			  storageProvider = provider
			, configuration   = providerFormData
		}
		locationArgs.append( generalFormData );
		var id = storageLocationService.addLocation( argumentCollection = locationArgs );
		var editLink = '<a href="#event.buildAdminLink( linkTo='assetmanager.editLocation', querystring='id=#id#' )#">#( completeFormData.name ?: '' )#</a>';

		messageBox.info( translateResource( uri="cms:assetmanager.location.added", data=[ editLink ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managelocations" ) );
	}

	function editLocation( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		prc.locationId = rc.id ?: "";
		prc.location   = storageLocationService.getLocation( prc.locationId );

		if ( IsStruct( prc.location.configuration ?: "" ) ) {
			prc.location.append( prc.location.configuration );
		}

		if ( prc.location.isEmpty() ) {
			messageBox.info( translateResource( uri="cms:assetmanager.location.not.found" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managelocations" ) );
		}

		var provider = prc.location.storageProvider ?: "filesystem";
		prc.providerTitle    = translateResource( "storage-providers.#provider#:title" );
		prc.formName         = formsService.getMergedFormName( "preside-objects.asset_storage_location.admin.edit", "storage-providers.#provider#" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager.managelocations.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.managelocations" )
		);

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:assetManager.editlocation.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.editlocation", queryString="id=#prc.locationId#" )
		);

		prc.pageIcon     = "picture-o";
		prc.pageTitle    = translateResource( uri="cms:assetManager.editlocation.page.title"   , data=[ prc.providerTitle ] );
		prc.pageSubTitle = translateResource( uri="cms:assetManager.editlocation.page.subtitle", data=[ prc.location.name ] );
	}

	function editLocationAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="storagelocations.manage" );

		var locationId = rc.id ?: "";
		var location   = storagelocationService.getLocation( locationId );

		if ( location.isEmpty() ) {
			messageBox.error( translateResource( uri="cms:assetmanager.location.not.found" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managelocations" ) );
		}

		var provider         = location.storageProvider;
		var generalFormName  = "preside-objects.asset_storage_location.admin.edit";
		var generalFormData  = event.getCollectionForForm( generalFormName );
		var providerFormName = "storage-providers.#provider#";
		var providerFormData = event.getCollectionForForm( providerFormName );
		var completeFormName = formsService.getMergedFormName( generalFormName, providerFormName );
		var completeFormData = event.getCollectionForForm( completeFormName );
		var validationResult = validateForm( completeFormName, completeFormData );

		storageProviderService.validateProvider(
			  id               = provider
			, configuration    = providerFormData
			, validationResult = validationResult
		);

		if ( !validationResult.validated() ) {
			var persist = completeFormData;
			persist.validationResult = validationResult;

			messageBox.error( translateResource( uri="cms:assetmanager.location.not.valid" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editLocation", queryString="id=" & locationId ), persistStruct=persist );
		}

		var locationArgs = {
			  id            = locationId
			, configuration = providerFormData
		}
		locationArgs.append( generalFormData );

		storageLocationService.updateLocation( argumentCollection = locationArgs );

		messageBox.info( translateResource( uri="cms:assetmanager.location.saved", data=[ generalFormData.name ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managelocations" ) );
	}

// PRIVATE VIEWLETS
	private string function searchBox( event, rc, prc, args={} ) {
		var prefetchCacheBuster = assetManagerService.getPrefetchCachebusterForAjaxSelect( [] );

		args.prefetchUrl = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#" );
		args.remoteUrl   = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="q=%QUERY" );

		return renderView( view="/admin/assetmanager/_searchBox", args=args );
	}

	private string function storageProviderPicker( event, rc, prc, args={} ) {
		var providers = storageProviderService.listProviders();
		args.providers = [];

		for( var provider in providers ) {
			args.providers.append({
				  id          = provider
				, title       = translateResource( "storage-providers.#provider#:title" )
				, description = translateResource( "storage-providers.#provider#:description" )
				, description = translateResource( "storage-providers.#provider#:description" )
				, iconClass   = translateResource( "storage-providers.#provider#:iconClass" )
			});
		}

		args.providers.sort( function( a, b ){
			return a.title < b.title ? -1 : 1;
		} );

		event.include( "/css/admin/specific/sitetree/" );

		return renderView( view="/admin/assetmanager/_storageProviderPicker", args=args );
	}

	private string function locationGridActions( event, rc, prc, args={} ) {
		return renderView( view="/admin/assetmanager/_locationGridActions", args=args );
	}

// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permitted = "";
		var permKey   = "assetmanager." & arguments.key;

		if ( Len( Trim( rc.folder ?: "" ) ) ) {
			permitted = hasCmsPermission( permissionKey=permKey, context="assetmanagerfolder", contextKeys=prc.permissionContext?:[] );

		} else {
			permitted = hasCmsPermission( permissionKey=permKey );
		}

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

	private void function _editAssetLocationInBackgroundThread( event, rc, prc, args={} ){
		assetManagerService.ensureAssetsAreInCorrectLocation( folderId=args.id ?: "" );
	}

	private string function _getAssetTooLargeMessage( event, rc, prc ) {
		var maxWidth      = Val( derivativeLimits.maxWidth      ?: "" );
		var maxHeight     = Val( derivativeLimits.maxHeight     ?: "" );
		var maxResolution = Val( derivativeLimits.maxResolution ?: "" );

		var messages = [];

		if ( maxWidth ) {
			messages.append( translateResource( uri="cms:assetmanager.image.too.large.max.width", data=[ NumberFormat( maxWidth ) ] ) );
		}
		if ( maxHeight ) {
			messages.append( translateResource( uri="cms:assetmanager.image.too.large.max.height", data=[ NumberFormat( maxHeight ) ] ) );
		}
		if ( maxResolution ) {
			messages.append( translateResource( uri="cms:assetmanager.image.too.large.max.resolution", data=[ NumberFormat( maxResolution ) ] ) );
		}

		return translateResource( uri="cms:assetmanager.image.too.large.for.derivatives" ) & "<br><br>" & ArrayToList( messages, " " );
	}
}