component extends="preside.system.base.AdminHandler" output=false {

	property name="assetManagerService"      inject="assetManagerService";
	property name="contentRendererService"          inject="contentRendererService";
	property name="imageManipulationService" inject="imageManipulationService";
	property name="messageBox"               inject="coldbox:plugin:messageBox";

	function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );


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
			rc.folder = prc.asset.asset_folder;
		}

		if ( Len( Trim( rc.folder ?: "" ) ) ) {
			prc.folderAncestors   = assetManagerService.getFolderAncestors( id=rc.folder ?: "" );
			prc.permissionContext = [];
			prc.inheritedPermissionContext = [];

			for( var f in prc.folderAncestors ){
				prc.permissionContext.prepend( f.id );
				prc.inheritedPermissionContext.prepend( f.id );
				event.addAdminBreadCrumb(
					  title = f.label
					, link  = event.buildAdminLink( linkTo="assetmanager", querystring="folder=#f.id#" )
				);
			}

			prc.folder = assetManagerService.getFolder( id=rc.folder );
			if ( prc.folder.recordCount ){
				prc.permissionContext.prepend( rc.folder );
				event.addAdminBreadCrumb(
					  title = prc.folder.label
					, link  = event.buildAdminLink( linkTo="assetmanager", querystring="folder=#prc.folder.id#" )
				);
			}
		}

		_checkPermissions( argumentCollection=arguments, key="general.navigate" );
	}

	function index( event, rc, prc ) output=false {
		var settings = getSetting( name="assetManager", defaultValue={} );

		_checkPermissions( argumentCollection=arguments, key="general.navigate" );

		event.includeData( {
			  maxFileSize       = settings.maxFileSize       ?: 10
			, allowedExtensions = settings.allowedExtensions ?: ""
		} );

		prc.rootFolderId = assetManagerService.getRootFolderId();
	}

	function addAssets( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var fileIds = ListToArray( rc.fileId ?: "" );

		prc.tempFileDetails = {};
		for( var fileId in fileIds ){
			prc.tempFileDetails[ fileId ] = assetManagerService.getTemporaryFileDetails( fileId );
		}
	}

	function addAssetAction( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		var fileId           = rc.fileId ?: "";
		var folder           = rc.folder ?: "";
		var formName         = "preside-objects.asset.admin.add";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = "";

		formData.asset_folder = folder;

		validationResult = validateForm( formName, formData );

		if ( validationResult.validated() ) {
			try {
				assetManagerService.saveTemporaryFileAsAsset(
					  tmpId     = fileId
					, folder    = folder
					, assetData = formData
				);
				event.renderData( data={ success=true, title=( rc.label ?: "" ) }, type="json" );
			} catch ( any e ) {
				event.renderData( data={
					  success = false
					, title   = translateResource( "cms:assetmanager.add.asset.unexpected.error.title" )
					, message = translateResource( "cms:assetmanager.add.asset.unexpected.error.message" )
				}, type="json" );
			}
		} else {
			event.renderData( data={
				  success          = false
				, validationResult = translateValidationMessages( validationResult )
			}, type="json" );
		}
	}

	function trashAssetAction( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.delete" );

		var assetId          = rc.asset ?: "";
		var asset            = assetManagerService.getAsset( assetId );
		var parentFolder     = asset.recordCount ? asset.asset_folder : "";
		var trashed          = "";

		try {
			trashed = assetManagerService.trashAsset( assetId );
		} catch ( any e ) {
			messageBox.error( translateResource( "cms:assetmanager.trash.asset.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", querystring="folder=#parentFolder#" ) );
		}

		if ( trashed ) {
			messageBox.info( translateResource( uri="cms:assetmanager.trash.asset.success", data=[ asset.label ] ) );
		} else {
			messageBox.error( translateResource( "cms:assetmanager.trash.asset.unexpected.error" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#parentFolder#" ) );
	}

	function renameFolderAction( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="folders.edit" );

		var success = assetManagerService.renameFolder(
			  id    = rc.folder ?: ""
			, label = rc.label  ?: ""
		);

		if ( success ) {
			event.renderData( data={ success=true }, type="json" );
		} else {
			event.renderData( data={ error=true }, type="json" );
		}
	}

	function addFolder( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="folders.add" );
	}

	function addFolderAction( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="folders.add" );

		var formName         = "preside-objects.asset_folder.admin.add";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = "";

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
			assetManagerService.addFolder( argumentCollection = formData );
		} catch ( any e ) {
			messageBox.error( translateResource( "cms:assetmanager.add.folder.unexpected.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.addFolder", querystring="folder=#formData.parent_folder#" ), persistStruct=formData );
		}

		messageBox.info( translateResource( uri="cms:assetmanager.folder.added.confirmation", data=[ formData.label ?: '' ] ) );
		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager.addFolder", queryString="folder=#formData.parent_folder#" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#formData.parent_folder#" ) );
		}
	}

	function trashFolderAction( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="folders.delete" );

		var folderId         = rc.folder ?: "";
		var folder           = assetManagerService.getFolder( folderId );
		var parentFolder     = folder.recordCount ? folder.parent_folder : "";
		var trashed          = "";

		try {
			trashed = assetManagerService.trashFolder( folderId );
		} catch ( any e ) {
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

	function uploadTempFileAction( event, rc, prc ) output=false {
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

	function deleteTempFile( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		try {
			assetManagerService.deleteTemporaryFile( tmpId=rc.fileId ?: "" );
		} catch( any e ) {
			// problems are inconsequential - temp files will be cleaned up later anyway
		}

		event.renderData( data={ success=true }, type="json" );
	}

	function previewTempFile( event, rc, prc ) output=false {
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

	function editAsset( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.edit" );
	}

	function editAssetAction( event, rc, prc ) output=false {
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
			success = false;
		}

		if ( success ) {
			messagebox.info( translateResource( uri="cms:assetmanager.asset.edit.success", data=[ formData.label ?: "" ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetManager", queryString="folder=#folderId#" ) );
		} else {
			messagebox.error( translateResource( "cms:assetmanager.asset.edit.unexpected.error" ) );
			persist = formData;
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=#assetId#" ), persistStruct=persist );
		}
	}

	function assetPickerBrowser( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.pick" );

		var allowedTypes = rc.allowedTypes ?: "";
		var multiple     = rc.multiple ?: "";

		prc.rootFolderId = assetManagerService.getRootFolderId();
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

	function assetPickerUploader( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="assets.upload" );

		event.setLayout( "adminModalDialog" );
		event.setView( "admin/assetmanager/assetPickerUploader" );
	}

	function getAssetsForAjaxPicker( event, rc, prc ) output=false {
		var records = assetManagerService.getAssetsForAjaxSelect(
			  maxRows      = rc.maxRows      ?: 1000
			, searchQuery  = rc.q            ?: ""
			, ids          = ListToArray( rc.values       ?: "" )
			, allowedTypes = ListToArray( rc.allowedTypes ?: "" )
		);
		var recordsWithIcons = [];

		for ( record in records ) {
			record.icon = renderAsset( record.value, "pickerIcon" );
			recordsWithIcons.append( record );
		}

		event.renderData( type="json", data=recordsWithIcons );
	}

	public void function pickerForEditorDialog( event, rc, prc ) output=false {
		var jsonConfig = rc.configJson ?: "";

		if ( Len( Trim( jsonConfig ) ) ) {
			try {
				rc.append( DeSerializeJson( UrlDecode( jsonConfig ) ) );
			} catch ( any e ){}
		}


		event.setLayout( "adminModalDialog" );
		event.setView( "admin/assetManager/pickerForEditorDialog" );
	}

	public void function getImageDetailsForCKEditorImageDialog( event, rc, prc ) output=false {
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

	public void function getAttachmentDetailsForCKEditorDialog( event, rc, prc ) output=false {
		var assetId = rc.asset ?: "";
		var asset   = assetManagerService.getAsset( assetId );

		if ( asset.recordCount ) {
			asset = QueryRowToStruct( asset );
			event.renderData( data=asset, type="json" );
		} else {
			event.renderData( data={}, type="json" );
		}
	}

	public void function renderEmbeddedImageForEditor( event, rc, prc ) output=false {
		var richContent = rc.embeddedImage ?: "";
		var rendered    = contentRendererService.renderEmbeddedImages( richContent );

		event.renderData( data=rendered );
	}

	public void function renderEmbeddedAttachmentForEditor( event, rc, prc ) output=false {
		var richContent = rc.embeddedAttachment ?: "";
		var rendered    = contentRendererService.renderEmbeddedAttachments( richContent );

		event.renderData( data=rendered );
	}

	public void function managePerms( event, rc, prc ) output=false {
		_checkPermissions( argumentCollection=arguments, key="folders.managePerms" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:assetmanager.managePerms.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function savePermsAction( event, rc, prc ) output=false {
		var folderId = rc.folder ?: "";
		var folderRecord = prc.folder ?: QueryNew( 'label' );

		_checkPermissions( argumentCollection=arguments, key="folders.managePerms" );

		if ( runEvent( event="admin.Permissions.saveContextPermsAction", private=true ) ) {
			messageBox.info( translateResource( uri="cms:assetmanager.permsSaved.confirmation", data=[ folderRecord.label ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.index", queryString="folder=#folderId#" ) );
		}

		messageBox.error( translateResource( uri="cms:assetmanager.permsSaved.error", data=[ folderRecord.label ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="assetmanager.managePerms", queryString="folder=#folderId#" ) );
	}

// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) output=false {
		var permitted = "";
		var permKey   = "assetmanager." & arguments.key;

		if ( Len( Trim( rc.folder ?: "" ) ) ) {
			permitted = hasPermission( permissionKey=permKey, context="assetmanagerfolder", contextKeys=prc.permissionContext?:[] );

		} else {
			permitted = hasPermission( permissionKey=permKey );
		}

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}
}