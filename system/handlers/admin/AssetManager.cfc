component extends="preside.system.base.AdminHandler" {

	property name="assetManagerService"      inject="assetManagerService";
	property name="websitePermissionService" inject="websitePermissionService";
	property name="formsService"             inject="formsService";
	property name="presideObjectService"     inject="presideObjectService";
	property name="contentRendererService"   inject="contentRendererService";
	property name="imageManipulationService" inject="imageManipulationService";
	property name="errorLogService"          inject="errorLogService";
	property name="messageBox"               inject="coldbox:plugin:messageBox";
	property name="datatableHelper"          inject="coldbox:myplugin:JQueryDatatablesHelpers";

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

		prc.folder        = assetManagerService.getFolder( id=rc.folder );
		prc.isTrashFolder = prc.folder.recordCount && assetManagerService.getTrashFolderId() == rc.folder;

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
		prc.trashFolderId = assetManagerService.getTrashFolderId();
		prc.trashCount    = assetManagerService.getTrashCount();
	}

	function addAssets( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var fileIds = ListToArray( rc.fileId ?: "" );
		var getMeta = IsTrue( getSystemSetting( "asset-manager", "retrieve_metadata" ) );

		prc.tempFileDetails = {};
		for( var fileId in fileIds ){
			prc.tempFileDetails[ fileId ] = assetManagerService.getTemporaryFileDetails( fileId, getMeta );
		}
	}

	function addAssetAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var fileId           = rc.fileId ?: "";
		var folder           = rc.folder ?: assetManagerService.getRootFolderId();
		var formName         = "preside-objects.asset.admin.add";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = "";

		formData.asset_folder = folder;

		validationResult = validateForm( formName, formData );

		if ( validationResult.validated() ) {
			try {
				var assetId = assetManagerService.saveTemporaryFileAsAsset(
					  tmpId     = fileId
					, folder    = folder
					, assetData = formData
				);

				event.renderData( type="json", data={
					  success = true
					, title   = ( rc.title ?: "" )
					, id      = assetId
				} );
			} catch( "PresideCMS.AssetManager.asset.wrong.type.for.folder" e ) {
				validationResult.addError( fieldname="folder", message=translateResource( uri="cms:assetmanager.folder.type.restriction.validation.message" ) );
			} catch( "PresideCMS.AssetManager.asset.too.big.for.folder" e ) {
				validationResult.addError( fieldname="folder", message=translateResource( uri="cms:assetmanager.folder.size.restriction.validation.message" ) );
			} catch ( any e ) {
				logError( e );
				event.renderData( data={
					  success = false
					, title   = translateResource( "cms:assetmanager.add.asset.unexpected.error.title" )
					, message = translateResource( "cms:assetmanager.add.asset.unexpected.error.message" )
				}, type="json" );
			}
		}

		if ( !validationResult.validated() ) {
			event.renderData( data={
				  success          = false
				, validationResult = translateValidationMessages( validationResult )
			}, type="json" );
		}
	}

	function addAssetsInPicker( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var fileIds = ListToArray( rc.fileId ?: "" );
		var getMeta = IsTrue( getSystemSetting( "asset-manager", "retrieve_metadata" ) );

		prc.tempFileDetails = {};
		for( var fileId in fileIds ){
			prc.tempFileDetails[ fileId ] = assetManagerService.getTemporaryFileDetails( fileId, getMeta );
		}

		event.setLayout( "adminModalDialog" );
		event.setView( "admin/assetManager/addAssetsInPicker" );
	}

	function trashAssetAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.delete" );

		var assetId          = rc.asset ?: "";
		var asset            = assetManagerService.getAsset( assetId );
		var parentFolder     = asset.recordCount ? asset.asset_folder : "";
		var alreadyTrashed   = parentFolder == assetManagerService.getTrashFolderId();
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
			break;
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager" ) );
	}

	function trashMultiAssetsAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.delete" );
		var parentFolder = "";
		var trashFolder  = assetManagerService.getTrashFolderId();
		var permanent    = false;

		for( var assetId in ListToArray( rc.id ?: "" ) ) {
			var asset = assetManagerService.getAsset( assetId );
			parentFolder = asset.recordCount ? asset.asset_folder : "";

			var alreadyTrashed = parentFolder == trashFolder;
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
		var trashFolderId = assetManagerService.getTrashFolderId();
		var fromTrash     = fromFolder == trashFolderId;

		if ( assetIds.len() ) {
			if ( !Len( Trim( fromFolder ) ) ) {
				var asset = assetmanagerService.getAsset( assetIds[1] );
				fromFolder = asset.asset_folder ?: "";
				fromTrash  = fromFolder == trashFolderId;
			}
			var success = true;
			try {
				if ( fromTrash ) {
					assetManagerService.restoreAssets(
						  assetIds  = assetIds
						, folderId  = folderId
						, fromTrash = fromTrash
					);
				} else {
					assetManagerService.moveAssets(
						  assetIds  = assetIds
						, folderId  = folderId
						, fromTrash = fromTrash
					);
				}
			} catch( "PresideCMS.AssetManager.asset.wrong.type.for.folder" e ) {
				success = false;
			} catch( "PresideCMS.AssetManager.asset.too.big.for.folder" e ) {
				success = false;
			}
			if ( !success ) {
				messagebox.error( translateResource( "cms:assetmanager.assets.could.not.be.moved.to.folder.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=" & fromFolder ) );
			}
		}

		if ( fromTrash ) {
			messagebox.info( translateResource( "cms:assetmanager.assets.restored.confirmation" ) );
		} else {
			messagebox.info( translateResource( "cms:assetmanager.assets.moved.confirmation" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=" & fromFolder ) );
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

		messageBox.info( translateResource( uri="cms:assetmanager.folder.edited.confirmation", data=[ formData.label ?: '' ] ) );
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

		var folderId           = rc.folder ?: "";
		var folderRestrictions = assetManagerService.getFolderRestrictions( id=folderId );

		event.includeData( folderRestrictions );
	}

	function uploadTempFileAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		if ( event.valueExists( "file" ) ) {
			var temporaryFileId = assetManagerService.uploadTemporaryFile( fileField="file" );

			if ( Len( Trim( temporaryFileId ) ) ) {
				event.renderData( data={ fileid=temporaryFileId }, type="json" );
			} else {
				event.renderData( data=translateResource( "cms:assetmanager.file.upload.error" ), type="text", statusCode=500 );
			}
		} else {
			event.renderData( data=translateResource( "cms:assetmanager.file.upload.error" ), type="text", statusCode=500 );
		}
	}

	function deleteTempFile( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		try {
			assetManagerService.deleteTemporaryFile( tmpId=rc.fileId ?: "" );
		} catch( any e ) {
			// problems are inconsequential - temp files will be cleaned up later anyway
		}

		event.renderData( data={ success=true }, type="json" );
	}

	function previewTempFile( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var fileId          = rc.tmpId ?: "";
		var fileDetails     = assetManagerService.getTemporaryFileDetails( fileId );
		var fileTypeDetails = "";

		// TODO: make this much smarter - thumbnail generation for images - preview for pdfs, etc.
		if ( StructCount( fileDetails ) ) {
			fileTypeDetails = assetManagerService.getAssetType( filename=filedetails.name );

			if ( ( fileTypeDetails.groupName ?: "" ) eq "image" ) {
				// brutal for now - no thumbnail generation, just spit out the file
				content reset="true" variable="#assetManagerService.getTemporaryFileBinary( fileId )#" type="#fileTypeDetails.mimeType#";abort;
			}
		}

		event.renderData( data="not found", type="text", statusCode=404 );
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

		prc.versions = assetManagerService.getAssetVersions( rc.asset );
		prc.assetType = assetManagerService.getAssetType( name=prc.asset.asset_type );
	}

	function editAssetAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );

		var assetId          = rc.asset  ?: "";
		var folderId         = rc.folder ?: "";
		var formName         = "preside-objects.asset.admin.edit";
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
		var multiple     = rc.multiple ?: "";

		prc.allowedTypes = assetManagerService.expandTypeList( ListToArray( allowedTypes ) );

		event.setLayout( "adminModalDialog" );

		prc._adminBreadCrumbs = [];
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:home.title" )
			, link  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="allowedTypes=#allowedTypes#" )
		);
		if ( Len( Trim( rc.folder ?: "" ) ) ) {
			prc.folderAncestors = assetManagerService.getFolderAncestors( id=rc.folder );
			for( var f in prc.folderAncestors ){
				event.addAdminBreadCrumb(
					  title = f.label
					, link  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="folder=#f.id#&allowedTypes=#allowedTypes#&multiple=#multiple#" )
				);
			}

			prc.folder = assetManagerService.getFolder( id=rc.folder );
			if ( prc.folder.recordCount ){
				event.addAdminBreadCrumb(
					  title = prc.folder.label
					, link  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="folder=#prc.folder.id#&allowedTypes=#allowedTypes#&multiple=#multiple#" )
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
			event.includeData( { allowedExtensions : extensionList, maxFileSize = maxFileSize } );
		}

		if ( !IsBoolean( multiple ) || !multiple ) {
			event.includeData( { maxFiles : 1 } );
		}

		event.setLayout( "adminModalDialog" );
		event.setView( "admin/assetmanager/assetPickerUploader" );
	}

	function ajaxSearchAssets( event, rc, prc ) {
		var records = assetManagerService.searchAssets(
			  maxRows      = rc.maxRows      ?: 1000
			, searchQuery  = rc.q            ?: ""
			, ids          = ListToArray( rc.values       ?: "" )
			, allowedTypes = ListToArray( rc.allowedTypes ?: "" )
		);
		var rootFolderName   = translateResource( "cms:assetmanager.root.folder" );
		var processedRecords = [];

		for ( record in records ) {
			record.icon = renderAsset( record.value, "pickerIcon" );
			if ( record.folder == "$root" ) {
				record.folder = rootFolderName;
			}

			processedRecords.append( record );
		}

		event.renderData( type="json", data=processedRecords );
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
		var gridFields = [ "title", "datemodified","id" ];
		var renderedOptions = [];
		var checkboxCol     = []

		var records = Duplicate( result.records );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( "asset", field, record[ field ], [ "adminDataTable", "admin" ] );
				if ( field == "title" ) {
					records[ field ][ records.currentRow ] = renderAsset( assetId=record.id, context="icon" ) & " " & records[ field ][ records.currentRow ];
				}
				if ( field == "id" ) {
					records[ field ][ records.currentRow ] = renderAsset( assetId=record.id, context="pickericon" );
				}
			}

			checkboxCol.append( renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
			if ( prc.isTrashFolder ) {
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
			, folder      = rc.folder ?: ""
		);
		var gridFields = [ "title", "datemodified","id" ];
		var renderedOptions = [];
		var checkboxCol     = []

		var records = Duplicate( result.records );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( "asset", field, record[ field ], [ "adminDataTable", "admin" ] );
				if ( field == "title" ) {
					records[ field ][ records.currentRow ] = renderAsset( assetId=record.id, context="icon" ) & " " & records[ field ][ records.currentRow ];
				}
				if ( field == "id" ) {
					records[ field ][ records.currentRow ] = renderAsset( assetId=record.id, context="pickericon" );
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
		if ( !prc.isTrashFolder && Len( Trim( rc.folder ?: "" ) ) && prc.folder.recordCount ) {
			var isSystemFolder = IsTrue( prc.folder.is_system_folder ?: "" );
			event.renderData(
				  data = renderView( view="admin/assetmanager/_folderTitleAndActions", args={ folderId=rc.folder, folderTitle=prc.folder.label, isSystemFolder=isSystemFolder } )
				, type = "html"
			);
		} else {
			event.renderData( data="", type="html" );
		}
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

			if ( !IsNull( binary ) ) {
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
			messageBox.info( translateResource( uri="cms:assetmanager.permsSaved.confirmation", data=[ folderRecord.label ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.index", queryString="folder=#folderId#" ) );
		}

		messageBox.error( translateResource( uri="cms:assetmanager.permsSaved.error", data=[ folderRecord.label ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managePerms", queryString="folder=#folderId#" ) );
	}

// PRIVATE VIEWLETS
	private string function searchBox( event, rc, prc, args={} ) {
		var prefetchCacheBuster = assetManagerService.getPrefetchCachebusterForAjaxSelect( [] );

		args.prefetchUrl = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#" );
		args.remoteUrl   = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="q=%QUERY" );

		return renderView( view="/admin/assetmanager/_searchBox", args=args );
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
}