/**
 * Provides APIs for programatically interacting with the Asset Manager (see [[assetmanager]] for more details)
 *
 * @singleton
 * @autodoc
 */
component displayName="AssetManager Service" {

// CONSTRUCTOR
	/**
	 * @defaultStorageProvider.inject     assetStorageProvider
	 * @temporaryStorageProvider.inject   tempStorageProvider
	 * @assetTransformer.inject           AssetTransformer
	 * @documentMetadataService.inject    DocumentMetadataService
	 * @systemConfigurationService.inject systemConfigurationService
	 * @storageLocationService.inject     storageLocationService
	 * @storageProviderService.inject     storageProviderService
	 * @systemConfigurationService.inject systemConfigurationService
	 * @configuredDerivatives.inject      coldbox:setting:assetManager.derivatives
	 * @configuredTypesByGroup.inject     coldbox:setting:assetManager.types
	 * @configuredFolders.inject          coldbox:setting:assetManager.folders
	 * @assetDao.inject                   presidecms:object:asset
	 * @assetVersionDao.inject            presidecms:object:asset_version
	 * @folderDao.inject                  presidecms:object:asset_folder
	 * @derivativeDao.inject              presidecms:object:asset_derivative
	 * @assetMetaDao.inject               presidecms:object:asset_meta
	 */
	public any function init(
		  required any    defaultStorageProvider
		, required any    temporaryStorageProvider
		, required any    assetTransformer
		, required any    documentMetadataService
		, required any    systemConfigurationService
		, required any    storageLocationService
		, required any    storageProviderService
		, required any    assetDao
		, required any    assetVersionDao
		, required any    folderDao
		, required any    derivativeDao
		, required any    assetMetaDao
		,          struct configuredDerivatives={}
		,          struct configuredTypesByGroup={}
		,          struct configuredFolders={}
	) {
 		_setAssetDao( arguments.assetDao );
 		_setAssetVersionDao( arguments.assetVersionDao );
		_setFolderDao( arguments.folderDao );

		_migrateFromLegacyRecycleBinApproach();
		_setupSystemFolders( arguments.configuredFolders );

		_setDefaultStorageProvider( arguments.defaultStorageProvider );
		_setAssetTransformer( arguments.assetTransformer );
		_setTemporaryStorageProvider( arguments.temporaryStorageProvider );
		_setDocumentMetadataService( arguments.documentMetadataService );
		_setSystemConfigurationService( arguments.systemConfigurationService );
		_setStorageLocationService( arguments.storageLocationService );
		_setStorageProviderService( arguments.storageProviderService );

		_setConfiguredDerivatives( arguments.configuredDerivatives );
		_setupConfiguredFileTypesAndGroups( arguments.configuredTypesByGroup );
		_setDerivativeDao( arguments.derivativeDao );
		_setAssetMetaDao( arguments.assetMetaDao );

		return this;
	}

// PUBLIC API METHODS
	public string function addFolder( required string label, string parent_folder="" ) {
		if ( not Len( Trim( arguments.parent_folder ) ) ) {
			arguments.parent_folder = getRootFolderId();
		} else {
			if ( isSystemFolder( arguments.parent_folder ) ) {
				throw( type="PresideCMS.AssetManager.invalidOperation", message="You cannot add child folders to system folders." );
			}
		}

		return _getFolderDao().insertData( arguments );
	}

	public boolean function editFolder( required string id, required struct data ) {
		if ( arguments.data.keyExists( "parent_folder" ) && not Len( Trim( arguments.data.parent_folder ) ) ) {
			arguments.data.parent_folder = getRootFolderId();
		}

		return _getFolderDao().updateData(
			  id   = arguments.id
			, data = arguments.data
		);
	}

	public boolean function setFolderLocation( required string id, required struct data ) {
		return editFolder( argumentCollection=arguments );
	}

	public query function getFolder( required string id, boolean includeHidden=false ) {
		var filter = { id=arguments.id };
		var extra  = [];
		if ( !includeHidden ) {
			extra.append( _getExcludeHiddenFilter() );
		}

		return _getFolderDao().selectData( filter=filter, extraFilters=extra );
	}

	public query function getFolderAncestors( required string id, boolean includeChildFolder=false ) {
		var folder        = getFolder( id=arguments.id );
		var ancestors     = QueryNew( folder.columnList );
		var ancestorArray = [];

		if ( arguments.includeChildFolder ){
			ancestorArray.append( folder );
		}

		while( folder.recordCount ){
			if ( not Len( Trim( folder.parent_folder ) ) ) {
				break;
			}
			folder = getFolder( id=folder.parent_folder );
			if ( folder.recordCount ) {
				ArrayAppend( ancestorArray, folder );
			}
		}

		for( var i=ancestorArray.len(); i gt 0; i-- ){
			for( folder in ancestorArray[i] ) {
				QueryAddRow( ancestors, folder );
			}
		}

		return ancestors;
	}

	public struct function getCascadingFolderSettings( required string id, required array settings ) {
		var folder            = getFolder( arguments.id );
		var collectedSettings = {};

		for( var setting in arguments.settings ) {
			if ( Len( Trim( folder[ setting ] ?: "" ) ) ) {
				collectedSettings[ setting ] = folder[ setting ];
			}
		}

		if ( StructCount( collectedSettings ) == arguments.settings.len() ) {
			return collectedSettings;
		}

		for( var folder in getFolderAncestors( arguments.id ) ) {
			for( var setting in arguments.settings ) {
				if ( !collectedSettings.keyExists( setting ) && Len( Trim( folder[ setting ] ?: "" ) ) ) {
					collectedSettings[ setting ] = folder[ setting ];
					if ( StructCount( collectedSettings ) == arguments.settings.len() ) {
						return collectedSettings;
					}
				}
			}
		}

		return collectedSettings;
	}

	public struct function getFolderRestrictions( required string id ) {
		var folderSettings = getCascadingFolderSettings( id=arguments.id, settings=[ "allowed_filetypes", "max_filesize_in_mb" ] );

		folderSettings.allowed_filetypes = ListToArray( folderSettings.allowed_filetypes ?: "" );
		folderSettings.max_filesize_in_mb = folderSettings.max_filesize_in_mb ?: "";

		if ( folderSettings.allowed_filetypes.len() ) {
			folderSettings.allowed_filetypes = expandTypeList( folderSettings.allowed_filetypes, true );
		}

		return {
			  maxFileSize       = IsNumeric( folderSettings.max_filesize_in_mb ) ? folderSettings.max_filesize_in_mb : 10
			, allowedExtensions = ArrayToList( folderSettings.allowed_filetypes )
		};
	}

	public boolean function areAssetsAllowedInFolder(
		  required array   assetIds
		, required string  folderId
		,          boolean throwIfNot = false
	) {
		var restrictions = getFolderRestrictions( arguments.folderId );
		var assets       = _getAssetDao().selectData(
			  filter       = { id = arguments.assetIds }
			, selectFields = [ "asset_type", "size", "asset_folder" ]
		);

		for( var asset in assets ) {
			var allowed = isAssetAllowedInFolder(
				  type            = asset.asset_type
				, size            = asset.size
				, currentFolderId = asset.asset_folder
				, folderId        = arguments.folderId
				, throwIfNot      = arguments.throwIfNot
				, restrictions    = restrictions
			);

			if ( !allowed ) {
				return false;
			}
		}

		return true;
	}

	public boolean function isAssetAllowedInFolder(
		  required string  type
		, required string  size
		, required string  folderId
		,          string  currentFolderId = ""
		,          boolean throwIfNot   = false
		,          struct  restrictions = getFolderRestrictions( arguments.folderId )
	) {
		var typeDisallowed = restrictions.allowedExtensions.len() && !ListFindNoCase( restrictions.allowedExtensions, "." & arguments.type );
		var sizeInMb       = arguments.size / 1048576;
		var tooBig         = restrictions.maxFileSize && sizeInMb > restrictions.maxFileSize;

		if ( typeDisallowed  ) {
			if ( arguments.throwIfNot ) {
				throw(
					  type    = "PresideCMS.AssetManager.asset.wrong.type.for.folder"
					, message = "Cannot add file to asset folder due to file type restrictions. File type supplied: [#arguments.type#]. Allowed types: [#restrictions.allowedExtensions#]"
				);
			}

			return false;
		}

		if ( tooBig ) {
			if ( arguments.throwIfNot ) {
				throw(
					  type    = "PresideCMS.AssetManager.asset.too.big.for.folder"
					, message = "Cannot add file to asset folder due to size restriction. Size of file: [#NumberFormat( sizeInMb, '0.00' )#Mb]. Maximum size: [#restrictions.maxFileSize#Mb]."
				);
			}

			return false;
		}

		if ( Len( Trim( arguments.currentFolderId ) ) ) {
			var currentLocation = _getStorageLocationForFolder( arguments.currentFolderId );
			var newLocation     = _getStorageLocationForFolder( arguments.folderId );

			if ( ( currentLocation.id ?: "" ) != ( newLocation.Id ?: "" ) ) {
				if ( arguments.throwIfNot ) {
					throw(
						  type    = "PresideCMS.AssetManager.folder.in.different.location"
						, message = "Cannot move file to asset folder due to folder location ([#( newLocation.name ?: 'default' )#]) being different from the source folder location ([#( currentLocation.name ?: 'default' )#])"
					);
				}

				return false;
			}
		}

		return true;
	}

	public query function getAllFoldersForSelectList( string parentString="/ ", string parentFolder="", query finalQuery ) {
		var folders = _getFolderDao().selectData(
			  selectFields = [ "id", "label" ]
			, orderBy      = "label"
			, filter       = {
				  parent_folder = Len( Trim( arguments.parentFolder ) ) ? arguments.parentFolder : getRootFolderId()
				, is_trashed    = false
			  }
		);

		if ( !StructKeyExists( arguments, "finalQuery" ) ) {
			arguments.finalQuery = QueryNew( 'id,label' );
		}

		for ( var folder in folders ) {
			QueryAddRow( finalQuery, { id=folder.id, label=parentString & folder.label } );

			finalQuery = getAllFoldersForSelectList( parentString & folder.label & " / ", folder.id, finalQuery );
		}

		return finalQuery;
	}

	public array function getFolderTree( string parentFolder="", string parentRestriction="none", permissionContext=[] ) {
		var tree   = [];
		var filter = { is_trashed = false };

		if ( Len( Trim( arguments.parentFolder ) ) ) {
			filter.parent_folder = arguments.parentFolder;
		} else {
			filter.id = getRootFolderId();
		}

		var folders = _getFolderDao().selectData(
			  selectFields = [ "asset_folder.id", "asset_folder.label", "asset_folder.access_restriction", "asset_folder.is_system_folder", "storage_location.name as storage_location" ]
			, filter       = filter
			, extraFilters = [ _getExcludeHiddenFilter() ]
			, groupBy      = "asset_folder.id"
			, orderBy      = "label"

		);

		for ( var folder in folders ) {
			if ( folder.access_restriction == "inherit" ) {
				folder.access_restriction = arguments.parentRestriction;
			}
			folder.permissionContext = arguments.permissionContext;
			folder.permissionContext.prepend( folder.id );

			folder.append({
				  children    = getFolderTree( folder.id, folder.access_restriction, folder.permissionContext )
				, asset_count = getAssetCount( folder.id )
			} );

			tree.append( folder );
		}

		return tree;
	}

	public array function expandTypeList( required array types, boolean prefixExtensionsWithPeriod=false ) {
		var expanded = [];
		var types    = _getTypes();

		for( var typeName in arguments.types ){
			if ( types.keyExists( typeName ) ) {
				expanded.append( typeName );
			} else {
				for( var typeName in listTypesForGroup( typeName ) ){
					expanded.append( typeName );
				}
			}
		}

		if ( arguments.prefixExtensionsWithPeriod ) {
			for( var i=1; i <= expanded.len(); i++ ){
				expanded[i] = "." & expanded[i];
			}
		}

		return expanded;
	}

	public struct function getAssetsForGridListing(
		  numeric startRow    = 1
		, numeric maxRows     = 10
		, string  orderBy     = ""
		, string  searchQuery = ""
		, string  folder      = ""
		, boolean trashed     = false

	) {

		var result        = { totalRecords = 0, records = "" };
		var parentFolder  = Len( Trim( arguments.folder ) ) ? arguments.folder : getRootFolderId();
		var titleField    = arguments.trashed ? "original_title" : "title";
		var args          = {
			  startRow     = arguments.startRow
			, maxRows      = arguments.maxRows
			, orderBy      = arguments.orderBy
			, selectFields = [ "id", "asset_folder", "#titleField# as title", "asset_type", "datemodified" ]
		};

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.filter       = "#titleField# like :q and is_trashed = :is_trashed";
			args.filterParams = {
				  is_trashed   = arguments.trashed
				, q            = { type="varchar", value="%" & arguments.searchQuery & "%" }
			};
			if ( !arguments.trashed ) {
				args.filter = "asset_folder = :asset_folder and " & args.filter;
				args.filterParams.asset_folder = parentFolder;
			}
		} else {
			args.filter = { is_trashed = arguments.trashed };
			if ( !arguments.trashed ) {
				args.filter.asset_folder = parentFolder;
			}
		}


		result.records = _getAssetDao().selectData( argumentCollection = args );

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			args.selectFields = [ "count( * ) as nRows" ];
			StructDelete( args, "startRow" );
			StructDelete( args, "maxRows" );

			result.totalRecords = _getAssetDao().selectData( argumentCollection = args ).nRows;
		}

		return result;
	}

	public array function searchAssets( array ids=[], string searchQuery="", array allowedTypes=[], numeric maxRows=100 ) {
		var assetDao    = _getAssetDao();
		var filter      = "( asset.is_trashed = :is_trashed )";
		var params      = { is_trashed = false };
		var types       = _getTypes();
		var records     = "";
		var result      = [];

		if ( arguments.ids.len() ) {
			filter &= " and ( asset.id in (:id) )";
			params.id = { value=ArrayToList( arguments.ids ), list=true };
		}
		if ( arguments.allowedTypes.len() ) {
			params.asset_type = { value="", list=true };

			for( var typeName in expandTypeList( arguments.allowedTypes ) ){
				params.asset_type.value = ListAppend( params.asset_type.value, typeName );
			}
			if ( Len( Trim( params.asset_type.value ) ) ){
				filter &= " and ( asset.asset_type in (:asset_type) )";
			} else {
				params.delete( "asset_type" );
			}
		}
		if ( Len( Trim( arguments.searchQuery ) ) ) {
			filter &= " and ( asset.title like (:title) or asset_folder.label like (:title) )";
			params.title = "%#arguments.searchQuery#%";
		}

		records = assetDao.selectData(
			  selectFields = [ "asset.id as value", "asset.${labelfield} as text", "asset_folder.${labelfield} as folder" ]
			, filter       = filter
			, filterParams = params
			, maxRows      = arguments.maxRows
			, orderBy      = "asset.datemodified desc"
		);

		for( var record in records ){
			record.folder = record.folder ?: "";
			result.append( record );
		}

		return result;
	}

	public string function getPrefetchCachebusterForAjaxSelect( array allowedTypes=[] ) {
		var filter  = "( asset.is_trashed = :is_trashed )";
		var params  = { is_trashed = false };
		var records = "";

		if ( arguments.allowedTypes.len() ) {
			params.asset_type = { value="", list=true };

			for( var typeName in expandTypeList( arguments.allowedTypes ) ){
				params.asset_type.value = ListAppend( params.asset_type.value, typeName );
			}
			if ( Len( Trim( params.asset_type.value ) ) ){
				filter &= " and ( asset.asset_type in (:asset_type) )";
			} else {
				params.delete( "asset_type" );
			}
		}

		records = _getAssetDao().selectData(
			  selectFields = [ "Max( asset.datemodified ) as lastmodified" ]
			, filter       = filter
			, filterParams = params
		);

		return records.recordCount ? Hash( records.lastmodified ) : Hash( Now() );
	}

	public boolean function folderHasContent( required string id ) {
		return _getAssetDao().dataExists( filter={ asset_folder=arguments.id, is_trashed=false } ) || _getFolderDao().dataExists( filter={ parent_folder=arguments.id, is_trashed=false } );
	}

	public boolean function trashFolder( required string id ) {
		if ( folderHasContent( arguments.id ) ) {
			return false;
		}

		var folder = getFolder( arguments.id );

		if ( !folder.recordCount || ( IsBoolean( folder.is_system_folder ?: "" ) && folder.is_system_folder ) ) {
			return false;
		}

		return _getFolderDao().updateData( id = arguments.id, data = {
			  is_trashed     = true
			, label          = CreateUUId()
			, original_label = folder.label
		} );
	}

	public string function uploadTemporaryFile( required string fileField ) {
		var tmpId         = CreateUUId();
		var storagePath   = "/" & tmpId & "/";
		var uploadedFile  = "";
		var transientPath = "";

		try {
			uploadedFile = FileUpload(
				  destination  = GetTempDirectory()
				, fileField    = arguments.filefield
				, nameConflict = "MakeUnique"
			);
		} catch( any e ) {
			return "";
		}

		storagePath  &= uploadedFile.serverFile;
		transientPath = uploadedFile.serverDirectory & "/" & uploadedFile.serverFile;

		_getTemporaryStorageProvider().putObject(
			  object = transientPath
			, path   = storagePath
		);

		FileDelete( transientPath );

		return tmpId;
	}

	public void function deleteTemporaryFile( required string tmpId ) {
		var details = getTemporaryFileDetails( arguments.tmpId );
		if ( Len( Trim( details.path ?: "" ) ) ) {
			_getTemporaryStorageProvider().deleteObject( details.path );
		}
	}

	public struct function getTemporaryFileDetails( required string tmpId, boolean includeMeta=false ) {
		var storageProvider = _getTemporaryStorageProvider();
		var files           = storageProvider.listObjects( "/#arguments.tmpId#/" );
		var details         = {};

		for( var file in files ) {
			if ( arguments.includeMeta ) {
				details = _getDocumentMetadataService().getMetadata( storageProvider.getObject( file.path ) );
			}

			StructAppend( details, file );

			details.title = details.title ?: ( details.name ?: "" );

			break;
		}

		return details;
	}

	public binary function getTemporaryFileBinary( required string tmpId ) {
		var details = getTemporaryFileDetails( arguments.tmpId );

		return _getTemporaryStorageProvider().getObject( details.path ?: "" );
	}

	public string function saveTemporaryFileAsAsset( required string tmpId, string folder, struct assetData = {} ) {
		var asset        = Duplicate( arguments.assetData );
		var fileDetails  = getTemporaryFileDetails( arguments.tmpId );

		if ( StructIsEmpty( fileDetails ) ) {
			return "";
		}

		asset.append( fileDetails, false );

		var fileBinary  = _getTemporaryStorageProvider().getObject( fileDetails.path );
		var newId       = addAsset( fileBinary, fileDetails.name, arguments.folder, asset );

		deleteTemporaryFile( arguments.tmpId );

		return newId;
	}

	/**
	 * Adds an asset into the Asset manager. The asset binary will be uploaded to the appropriate storage
	 * location for the given folder.
	 *
	 * @autodoc
	 * @fileBinary.hint Binary data of the file
	 * @fileName.hint   Uploaded filename (asset type information will be retrieved from here)
	 * @folder.hint     Either folder ID or name of a configured system folder
	 * @assetData.hint  Structure of additional data that can be saved against the [[presideobject-asset]] record
	 *
	 */
	public string function addAsset( required binary fileBinary, required string fileName, required string folder, struct assetData={} ) {
		var fileTypeInfo = getAssetType( filename=arguments.fileName, throwOnMissing=true );
		var newFileName  = "/uploaded/" & CreateUUId() & "." & fileTypeInfo.extension;
		var asset        = Duplicate( arguments.assetData );

		asset.asset_folder     = resolveFolderId( arguments.folder );
		asset.asset_type       = fileTypeInfo.typeName;
		asset.storage_path     = newFileName;
		asset.size             = asset.size  ?: Len( arguments.fileBinary );
		asset.title            = asset.title ?: "";

		isAssetAllowedInFolder(
			  type       = asset.asset_type
			, size       = asset.size
			, folderId   = asset.asset_folder
			, throwIfNot = true
		);

		_getStorageProviderForFolder( asset.asset_folder ).putObject(
			  object = arguments.fileBinary
			, path   = newFileName
		);

		if ( !Len( Trim( asset.title ) ) ) {
			asset.title = arguments.fileName;
		}

		if ( _autoExtractDocumentMeta() ) {
			asset.raw_text_content = _getDocumentMetadataService().getText( arguments.fileBinary );
		}

		if ( fileTypeInfo.groupName == "image" ) {
			asset.append( _getImageInfo( arguments.fileBinary ) );
		}

		if ( not Len( Trim( asset.asset_folder ) ) ) {
			asset.asset_folder = getRootFolderId();
		}

		var newId = _getAssetDao().insertData( data=asset );

		if ( _autoExtractDocumentMeta() ) {
			_saveAssetMetaData( assetId=newId, metaData=_getDocumentMetadataService().getMetaData( arguments.fileBinary ) );
		}

		return newId;
	}

	public boolean function addAssetVersion( required string assetId, required binary fileBinary, required string fileName, boolean makeActive=true  ) {
		var originalAsset = getAsset( id=arguments.assetId, selectFields=[ "asset_type", "asset_folder" ] );

		if( !originalAsset.recordCount ) {
			return false;
		}

		var originalFileTypeInfo = getAssetType( name=originalAsset.asset_type, throwOnMissing=true );
		var fileTypeInfo         = getAssetType( filename=arguments.fileName, throwOnMissing=true );

		if ( fileTypeInfo.mimeType != originalFileTypeInfo.mimeType ) {
			throw( type="AssetManager.mismatchedMimeType", message="The mime type of the uploaded file, [#fileTypeInfo.mimeType#], does not match that of the original version [#originalFileTypeInfo.mimeType#]." );
		}

		var newFileName          = "/uploaded/" & CreateUUId() & "." & fileTypeInfo.extension;
		var versionId            = "";
		var assetVersion         = {
			  asset        = arguments.assetId
			, asset_type   = fileTypeInfo.typeName
			, storage_path = newFileName
			, size         = Len( arguments.fileBinary )
			, version_number = _getNextAssetVersionNumber( arguments.assetId )
		};

		if ( _autoExtractDocumentMeta() ) {
			assetVersion.raw_text_content = _getDocumentMetadataService().getText( arguments.fileBinary );
		}

		_getStorageProviderForFolder( originalAsset.asset_folder ).putObject( object = arguments.fileBinary, path = newFileName );

		versionId = _getAssetVersionDao().insertData( data=assetVersion );

		if ( arguments.makeActive ) {
			makeVersionActive( arguments.assetId, versionId );
		}

		if ( _autoExtractDocumentMeta() ) {
			_saveAssetMetaData(
				  assetId   = arguments.assetId
				, versionId = versionId
				, metaData  = _getDocumentMetadataService().getMetaData( arguments.fileBinary )
			);
		}

		return true;
	}

	public string function getRawTextContent( required string assetId ) {
		var asset = getAsset( id=arguments.assetId, selectFields=[ "asset_type", "raw_text_content" ] );

		if ( asset.recordCount && asset.asset_type != "image" ) {
			if ( Len( Trim( asset.raw_text_content ) ) ) {
				return asset.raw_text_content;
			}
		}

		if ( _autoExtractDocumentMeta() ) {
			var fileBinary = getAssetBinary( arguments.assetId );
			if ( !IsNull( fileBinary ) ) {
				var rawText = _getDocumentMetadataService().getText( fileBinary );
				if ( Len( Trim( rawText ) ) ) {
					_getAssetDao().updateData( id=arguments.assetId, data={ raw_text_content=rawText } );
				}

				return rawText;
			}
		}

		return "";
	}

	public boolean function editAsset( required string id, required struct data ) {
		return _getAssetDao().updateData( id=arguments.id, data=arguments.data );
	}

	public boolean function moveAssets( required array assetIds, required string folderId ) {
		var folder = getFolder( arguments.folderId );
		if ( folder.recordCount ) {
			areAssetsAllowedInFolder(
				  assetIds   = arguments.assetIds
				, folderId   = arguments.folderId
				, throwIfNot = true
			);

			return _getAssetDao().updateData(
				  filter = { id = arguments.assetIds }
				, data   = { asset_folder = arguments.folderId }
			);
		}

		return false;
	}

	public boolean function restoreAssets( required array assetIds, required string folderId ) {
		var folder             = getFolder( arguments.folderId );
		var restoredAssetCount = 0;

		if ( folder.recordCount ) {
			areAssetsAllowedInFolder(
				  assetIds   = arguments.assetIds
				, folderId   = arguments.folderId
				, throwIfNot = true
			);

			for( var assetId in arguments.assetIds ) {
				var asset = getAsset( id=assetId, selectFields=[ "original_title", "asset_type", "trashed_path", "asset_folder", "active_version" ] );
				if ( asset.recordCount ) {
					var newPath = "/uploaded/" & LCase( assetId & "." & asset.asset_type );
					var storageProvider = _getStorageProviderForFolder( asset.asset_folder );

					storageProvider.restoreObject( asset.trashed_path, newPath );
					if ( Len( Trim( asset.active_version ) ) ) {
						_getAssetVersionDao().updateData( id=asset.active_version, data={
							  is_trashed     = false
							, storage_path   = newPath
							, trashed_path   = ""
						} );
					}

					_restoreAssociatedFiles( assetId, storageProvider );

					restoredAssetCount += _getAssetDao().updateData( id=assetId, data={
						  asset_folder   = arguments.folderId
						, title          = asset.original_title
						, is_trashed     = false
						, storage_path   = newPath
						, original_title = ""
						, trashed_path   = ""
					} );


				}
			}

			return restoredAssetCount;
		}

		return false;
	}

	public struct function getAssetType( string filename="", string name=ListLast( arguments.fileName, "." ), boolean throwOnMissing=false ) {
		var types = _getTypes();

		if ( StructKeyExists( types, arguments.name ) ) {
			return types[ arguments.name ];
		}

		if ( not arguments.throwOnMissing ) {
			return {};
		}

		throw(
			  type    = "assetManager.fileTypeNotFound"
			, message = "The file type, [#arguments.name#], could not be found"
		);
	}

	public array function listTypesForGroup( required string groupName ) {
		var groups = _getGroups();

		return groups[ arguments.groupName ] ?: [];
	}

	public query function getAsset( required string id, array selectFields=[], boolean throwOnMissing=false ) {
		var asset = Len( Trim( arguments.id ) ) ? _getAssetDao().selectData( id=arguments.id, selectFields=arguments.selectFields ) : QueryNew('');

		if ( asset.recordCount or not throwOnMissing ) {
			return asset;
		}

		throw(
			  type    = "AssetManager.assetNotFound"
			, message = "Asset with id [#arguments.id#] not found"
		);
	}

	public binary function getAssetBinary( required string id, string versionId="", boolean throwOnMissing=false, boolean isTrashed=false ) {
		var assetBinary = "";
		var storagePathField = arguments.isTrashed ? "trashed_path as storage_path" : "storage_path";
		var asset       = Len( Trim( arguments.versionId ) )
			? getAssetVersion( assetId=arguments.id, versionId=arguments.versionId, throwOnMissing=arguments.throwOnMissing, selectFields=[ "asset_version.#storagePathField#", "asset.asset_folder" ] )
			: getAsset( id=arguments.id, throwOnMissing=arguments.throwOnMissing, selectFields=[ storagePathField, "asset_folder" ] );

		if ( asset.recordCount ) {
			return _getStorageProviderForFolder( asset.asset_folder ).getObject( asset.storage_path, arguments.isTrashed );
		}
	}

	public string function getAssetEtag( required string id, string derivativeName="", string versionId="", boolean throwOnMissing=false, boolean isTrashed=false ) {
		var asset            = "";
		var storagePathField = arguments.isTrashed ? "trashed_path as storage_path" : "storage_path";

		if ( Len( Trim( arguments.derivativeName ) ) ) {
			asset = getAssetDerivative(
				  assetId        = arguments.id
				, versionId      = arguments.versionId
				, derivativeName = arguments.derivativeName
				, throwOnMissing = arguments.throwOnMissing
				, selectFields   = [ "asset_derivative.storage_path", "asset.asset_folder" ]
			);
		} else {
			asset = Len( Trim( arguments.versionId ) )
				? getAssetVersion( assetId=arguments.id, versionId=arguments.versionId, throwOnMissing=arguments.throwOnMissing, selectFields=[ "asset_version.#storagePathField#", "asset.asset_folder" ] )
				: getAsset( id=arguments.id, throwOnMissing=arguments.throwOnMissing, selectFields=[ "asset.#storagePathField#", "asset.asset_folder" ] );
		}

		if ( asset.recordCount ) {
			var assetInfo = _getStorageProviderForFolder( asset.asset_folder ).getObjectInfo( asset.storage_path, arguments.isTrashed );
			var etag      = LCase( Hash( SerializeJson( assetInfo ) ) )

			return Left( etag, 8 );
		}

		return "";
	}

	public boolean function trashAsset( required string id ) {
		var assetDao    = _getAssetDao();
		var asset       = assetDao.selectData( id=arguments.id, selectFields=[ "storage_path", "title", "asset_folder", "active_version" ] );
		var trashedPath = "";

		if ( !asset.recordCount ) {
			return false;
		}

		trashedPath = _getStorageProviderForFolder( asset.asset_folder ).softDeleteObject( asset.storage_path );
		if( asset.active_version.len() ) {
			_getAssetVersionDao().updateData(
				  id   = asset.active_version
				, data = { is_trashed=true, trashed_path = trashedPath }
			);
		}

		_deleteAssociatedFiles(
			  assetId    = arguments.id
			, folderId   = asset.asset_folder
			, softDelete = true
		);

		return assetDao.updateData( id=arguments.id, data={
			  trashed_path   = trashedPath
			, title          = CreateUUId()
			, original_title = asset.title
			, is_trashed     = true
		} );
	}

	public boolean function permanentlyDeleteAsset( required string id ) {
		var assetDao    = _getAssetDao();
		var asset       = assetDao.selectData( id=arguments.id, selectFields=[ "trashed_path", "title", "asset_folder" ] );
		var trashedPath = "";

		if ( !asset.recordCount ) {
			return false;
		}

		_getStorageProviderForFolder( asset.asset_folder ).deleteObject( asset.trashed_path, true );
		_deleteAssociatedFiles( arguments.id, asset.asset_folder );

		return assetDao.deleteData( id=arguments.id );
	}

	public query function getAssetDerivative( required string assetId, required string derivativeName, string versionId="", array selectFields=[] ) {
		var derivativeDao      = _getDerivativeDao();
		var signature          = getDerivativeConfigSignature( arguments.derivativeName );
		var derivative         = "";
		var lockName           = "getAssetDerivative( #arguments.assetId#, #arguments.derivativeName#, #arguments.versionId# )";
		var selectFilter       = "asset_derivative.asset = :asset_derivative.asset and asset_derivative.label = :asset_derivative.label";
		var selectFilterParams = {
			  "asset_derivative.asset"         = arguments.assetId
			, "asset_derivative.label"         = arguments.derivativeName & signature
		};

		if ( Len( Trim( arguments.versionId ) ) ) {
			selectFilter &= " and asset_derivative.asset_version = :asset_derivative.asset_version";
			selectFilterParams[ "asset_derivative.asset_version" ] = arguments.versionId;
		} else {
			selectFilter &= " and asset_derivative.asset_version is null";
		}

		lock type="readonly" name=lockName timeout=5 {
			derivative = derivativeDao.selectData( filter=selectFilter, filterParams=selectFilterParams, selectFields=arguments.selectFields );
			if ( derivative.recordCount ) {
				return derivative;
			}
		}

		lock type="exclusive" name=lockName timeout=120 {
			createAssetDerivative( assetId=arguments.assetId, versionId=arguments.versionId, derivativeName=arguments.derivativeName );

			return derivativeDao.selectData( filter=selectFilter, filterParams=selectFilterParams, selectFields=arguments.selectFields );
		}
	}

	public binary function getAssetDerivativeBinary( required string assetId, required string derivativeName, string versionId="" ) {
		var derivative = getAssetDerivative(
			  assetId        = arguments.assetId
			, derivativeName = arguments.derivativeName
			, versionId      = arguments.versionId
			, selectFields   = [ "asset_derivative.storage_path", "asset.asset_folder" ]
		);

		if ( derivative.recordCount ) {
			return _getStorageProviderForFolder( derivative.asset_folder ).getObject( derivative.storage_path );
		}
	}

	public string function createAssetDerivativeWhenNotExists(
		  required string assetId
		, required string derivativeName
		,          string versionId       = getCurrentVersionId( arguments.assetId )
		,          array  transformations = _getPreconfiguredDerivativeTransformations( arguments.derivativeName )
	) {
		var derivativeDao = _getDerivativeDao();
		var signature     = getDerivativeConfigSignature( arguments.derivativeName );
		var selectFilter  = "asset_derivative.asset = :asset_derivative.asset and asset_derivative.label = :asset_derivative.label";
		var filterParams  = { "asset_derivative.asset" = arguments.assetId, "asset_derivative.label" = arguments.derivativeName & signature };

		if ( Len( Trim( arguments.versionId ) ) ) {
			selectFilter &= " and asset_derivative.asset_version = :asset_derivative.asset_version";
			filterParams[ "asset_derivative.asset_version" ] = arguments.versionId;
		} else {
			selectFilter &= " and asset_derivative.asset_version is null";
		}

		if ( !derivativeDao.dataExists( filter=selectFilter, filterParams=filterParams ) ) {
			return createAssetDerivative( argumentCollection = arguments );
		}
	}

	public string function createAssetDerivative(
		  required string assetId
		, required string derivativeName
		,          string versionId = ""
		,          array  transformations = _getPreconfiguredDerivativeTransformations( arguments.derivativeName )
	) {
		var signature       = getDerivativeConfigSignature( arguments.derivativeName );
		var asset           = Len( Trim( arguments.versionId ) )
			? getAssetVersion( assetId=arguments.assetId, versionId=arguments.versionId, throwOnMissing=true, selectFields=[ "asset_version.storage_path", "asset.asset_folder" ] )
			: getAsset( id=arguments.assetId, throwOnMissing=true, selectFields=[ "storage_path", "asset_folder" ] );

		var assetBinary     = getAssetBinary( id=arguments.assetId, versionId=arguments.versionId, throwOnMissing=true );
		var fileext         = ListLast( asset.storage_path, "." );
		var filename        = arguments.assetId & ( Len( Trim( arguments.versionId ) ) ? ".#arguments.versionId#" : "" ) & ".#fileext#";
		var derivativeSlug  = ReReplace( arguments.derivativeName, "\W", "_", "all" ) & "_" & signature;
		var storagePath     = "/derivatives/#derivativeSlug#/#filename#";

		for( var transformation in transformations ) {
			if ( not Len( Trim( transformation.inputFileType ?: "" ) ) or transformation.inputFileType eq fileext ) {
				assetBinary = _applyAssetTransformation(
					  assetBinary          = assetBinary
					, transformationMethod = transformation.method ?: ""
					, transformationArgs   = transformation.args   ?: {}
				);

				if ( Len( Trim( transformation.outputFileType ?: "" ) ) ) {
					storagePath = ReReplace( storagePath, "\.#fileext#$", "." & transformation.outputFileType );
					fileext = transformation.outputFileType;
				}
			}
		}
		var assetType = getAssetType( filename=storagePath, throwOnMissing=true );

		_getStorageProviderForFolder( asset.asset_folder ).putObject( assetBinary, storagePath );

		return _getDerivativeDao().insertData( {
			  asset_type    = assetType.typeName
			, asset         = arguments.assetId
			, asset_version = arguments.versionId
			, label         = arguments.derivativeName & signature
			, storage_path  = storagePath
		} );
	}

	public struct function getAssetPermissioningSettings( required string assetId ) {
		var asset    = getAsset( arguments.assetId );
		var settings = {
			  contextTree                        = [ arguments.assetId ] //ListToArray( ValueList( folders.id ) ) };
			, restricted                         = false
			, fullLoginRequired                  = false
			, grantAcessToAllLoggedInUsers       = false
		}

		if ( !asset.recordCount ){ return settings; }

		var folders = getFolderAncestors( asset.asset_folder, true );

		for( var folder in folders ){ settings.contextTree.append( folder.id ); }

		if ( asset.access_restriction != "inherit" ) {
			settings.restricted                   = asset.access_restriction == "full";
			settings.fullLoginRequired            = IsBoolean( asset.full_login_required ) && asset.full_login_required;
			settings.grantAcessToAllLoggedInUsers = IsBoolean( asset.grantaccess_to_all_logged_in_users ) && asset.grantaccess_to_all_logged_in_users;

			return settings;
		}


		for( var folder in folders ) {
			if ( folder.access_restriction != "inherit" ) {
				settings.restricted                   = folder.access_restriction == "full";
				settings.fullLoginRequired            = IsBoolean( folder.full_login_required ) && folder.full_login_required;
				settings.grantAcessToAllLoggedInUsers = IsBoolean( folder.grantaccess_to_all_logged_in_users ) && folder.grantaccess_to_all_logged_in_users;

				return settings;
			}
		}

		return settings;
	}

	public any function listEditorDerivatives(){
		var derivatives = _getConfiguredDerivatives();
		var publicDerivatives = [];

		for( var derivative in derivatives ) {
			if ( derivatives[ derivative ].keyExists( "inEditor" ) ) {
				if( IsBoolean( derivatives[ derivative ].inEditor ?: "" ) && derivatives[ derivative ].inEditor ){
				    publicDerivatives.append( derivative );
			   	}
			}
		}

		return publicDerivatives;
	}

	public boolean function isDerivativePubliclyAccessible( required string derivative ) {
		var derivatives = _getConfiguredDerivatives();

		return ( derivatives[ arguments.derivative ].permissions ?: "inherit" ) == "public";
	}

	public string function getDerivativeConfigSignature( required string derivative ) {
		var derivatives = _getConfiguredDerivatives();

		if ( derivatives.keyExists( arguments.derivative ) ) {
			if ( !derivatives[ arguments.derivative ].keyExists( "signature" ) ) {
				derivatives[ arguments.derivative ].signature = LCase( Hash( SerializeJson( derivatives[ arguments.derivative ] ) ) );
			}

			return derivatives[ arguments.derivative ].signature;
		}

		return "";
	}

	public boolean function isSystemFolder( required string folderId ) {
		return _getFolderDao().dataExists( filter={ id=arguments.folderId, is_system_folder=true } );
	}

	public string function resolveFolderId( required string folderId ) {
		var folder = _getFolderDao().selectData( selectFields=[ "id" ], filter={ system_folder_key=arguments.folderId } );

		if ( folder.recordCount ) {
			return folder.id;
		}

		return arguments.folderId;
	}

	public boolean function makeVersionActive( required string assetId, required string versionId ) {
		var versionToMakeActive = _getAssetVersionDao().selectData(
			  id           = arguments.versionId
			, selectFields = [
				  "storage_path"
				, "size"
				, "asset_type"
				, "raw_text_content"
				, "created_by"
				, "updated_by"
			]
		);

		var versionImageDimension =  _getImageInfo( getAssetBinary( arguments.assetId, arguments.versionId ) );

		if ( versionToMakeActive.recordCount ) {
			return _getAssetDao().updateData( id=arguments.assetId, data={
				  active_version   = arguments.versionId
				, storage_path     = versionToMakeActive.storage_path
				, size             = versionToMakeActive.size
				, asset_type       = versionToMakeActive.asset_type
				, raw_text_content = versionToMakeActive.raw_text_content
				, created_by       = versionToMakeActive.created_by
				, updated_by       = versionToMakeActive.updated_by
				, width            = versionImageDimension.width  ?: ""
				, height           = versionImageDimension.height ?: ""
			} );
		}

		return false;
	}

	public boolean function deleteAssetVersion( required string assetId, required string versionId ) {
		var asset = getAsset( id=arguments.assetId, selectFields=[ "active_version", "asset_folder" ] );

		if ( !asset.recordCount || asset.active_version == arguments.versionId ) {
			return false;
		}

		_deleteAssociatedFiles( arguments.assetId, asset.asset_folder, arguments.versionId );

		return _getAssetVersionDao().deleteData(
			filter = { id=arguments.versionId, asset=arguments.assetId }
		);
	}

	public query function getAssetVersions( required string assetId, array selectFields=[] ) {
		return _getAssetVersionDao().selectData(
			  filter       = { asset = arguments.assetId }
			, orderBy      = "version_number desc"
			, selectfields = arguments.selectfields
		);
	}

	public query function getAssetVersion( required string assetId, required string versionId, array selectFields=[], boolean throwOnMissing=false ) {
		var assetVersion = _getAssetVersionDao().selectData(
			  selectFields = arguments.selectFields
			, filter       = { id=arguments.versionId, asset=arguments.assetId }
		);

		if ( throwOnMissing && !assetVersion.recordCount ) {
			throw(
				  type    = "AssetManager.versionNotFound"
				, message = "Asset version with asset id [#arguments.assetId#] and version id [#arguments.versionId#] not found"
			);
		}

		return assetVersion;
	}

	public string function getCurrentVersionId( required string assetId ) {
		if ( Len( Trim( arguments.assetId ) ) ) {
			var asset = getAsset( id=arguments.assetId, selectFields=[ "active_version" ] );

			return asset.active_version ?: "";
		}

		return "";
	}

	public numeric function getTrashCount() {
		var result = _getAssetDao().selectData(
			  selectFields = [ "Count(1) as asset_count" ]
			, filter       = { is_trashed=true }
		);

		return Val( result.asset_count ?: "" );
	}

	public numeric function getAssetCount( required string folderId ) {
		var result = _getAssetDao().selectData(
			  selectFields = [ "Count(1) as asset_count" ]
			, filter       = { is_trashed=false, asset_folder=arguments.folderId }
		);

		return Val( result.asset_count ?: "" );
	}

// PRIVATE HELPERS
	private void function _migrateFromLegacyRecycleBinApproach() {
		var folderDao   = _getFolderDao();
		var trashFolder = folderDao.selectData( selectFields=[ "id" ], filter="parent_folder is null and label = :label", filterParams={ label="$recycle_bin" } );

		if ( trashFolder.recordCount ) {
			var assetDao = _getAssetDao();

			assetDao.updateData(
				  filter = { asset_folder = trashFolder.id }
				, data   = { is_trashed = true }
			);

			assetDao.updateData(
				  filter = "is_trashed IS NULL"
				, data   = { is_trashed = false }
			);

			folderDao.updateData(
				  filter = { parent_folder = trashFolder.id }
				, data   = { is_trashed = true }
			);

			folderDao.updateData(
				  filter = "is_trashed IS NULL"
				, data   = { is_trashed = false }
			);

			folderDao.updateData(
				  id     = trashFolder.id
				, data   = { is_trashed = true, label="$legacy_recycle_bin" }
			);
		}
	}

	private void function _setupSystemFolders( required struct configuredFolders ) {
		var dao         = _getFolderDao();
		var rootFolder  = dao.selectData( selectFields=[ "id" ], filter="parent_folder is null and label = :label", filterParams={ label="$root" } );


		if ( rootFolder.recordCount ) {
			_setRootFolderId( rootFolder.id );
		} else {
			_setRootFolderId( dao.insertData( data={ label="$root" } ) );
		}

		for( var folderId in arguments.configuredFolders ){
			_setupConfiguredSystemFolder( folderId, arguments.configuredFolders[ folderId ], getRootFolderId() );
		}
	}

	private void function _setupConfiguredSystemFolder( required string id, required struct settings, required string parentId ) {
		var dao            = _getFolderDao();
		var existingRecord = dao.selectData( selectfields=[ "id" ], filter={ is_system_folder=true, system_folder_key=arguments.id } )
		var folderId       = existingRecord.id ?: "";

		if ( !Len( Trim( folderId ) ) ) {
			var data = duplicate( arguments.settings );

			data.label             = data.label ?: ListLast( arguments.id, "." );
			data.is_system_folder  = true;
			data.system_folder_key = arguments.id;
			data.parent_folder     = arguments.parentId;

			folderId = dao.insertData( data );
		}

		var children = arguments.settings.children ?: {};
		for( var childId in children ){
			_setupConfiguredSystemFolder( ListAppend( arguments.id, childId, "." ), arguments.settings.children[ childId ], folderId );
		}
	}

	private binary function _applyAssetTransformation( required binary assetBinary, required string transformationMethod, required struct transformationArgs ) {
		var args        = Duplicate( arguments.transformationArgs );

		// todo, sanity check the input

		args.asset = arguments.assetBinary;
		return _getAssetTransformer()[ arguments.transformationMethod ]( argumentCollection = args );
	}

	private array function _getPreconfiguredDerivativeTransformations( required string derivativeName ) {
		var configured = _getConfiguredDerivatives();

		if ( StructKeyExists( configured, arguments.derivativeName ) ) {
			return configured[ arguments.derivativeName ].transformations ?: [];
		}

		throw(
			  type    = "AssetManagerService.missingDerivativeConfiguration"
			, message = "No configured asset transformations were found for an asset derivative with name, [#arguments.derivativeName#]"
		);
	}

	private void function _setupConfiguredFileTypesAndGroups( required struct typesByGroup ) {
		var types  = {};
		var groups = {};

		for( var groupName in typesByGroup ){
			if ( IsStruct( typesByGroup[ groupName ] ) ) {
				groups[ groupName ] = StructKeyArray( typesByGroup[ groupName ] );
				for( var typeName in typesByGroup[ groupName ] ) {
					var type = typesByGroup[ groupName ][ typeName ];
					types[ typeName ] = {
						  typeName          = typeName
						, groupName         = groupName
						, extension         = type.extension ?: typeName
						, mimetype          = type.mimetype  ?: ""
						, serveAsAttachment = IsBoolean( type.serveAsAttachment ?: "" ) && type.serveAsAttachment
					};
				}
			}
		}

		_setGroups( groups );
		_setTypes( types );
	}

	private void function _saveAssetMetaData( required string assetId, required struct metaData, string versionId="" ) {
		var dao = _getAssetMetaDao();

		dao.deleteData( filter={ asset=assetId } );
		for( var key in arguments.metaData ) {
			dao.insertData( {
				  asset         = arguments.assetId
				, asset_version = arguments.versionId
				, key           = key
				, value         = arguments.metaData[ key ]
			} );
		}
	}

	private boolean function _autoExtractDocumentMeta() {
		var setting = _getSystemConfigurationService().getSetting( "asset-manager", "retrieve_metadata" );

		return IsBoolean( setting ) && setting;
	}

	private struct function _getExcludeHiddenFilter() {
		return { filter="hidden is null or hidden = 0" }
	}

	private numeric function _getNextAssetVersionNumber( required string assetId ) {
		_setupFirstVersionForAssetIfNoActiveVersion( arguments.assetId );

		var latestVersion = _getAssetVersionDao().selectData(
			  filter = { asset = arguments.assetId }
			, selectFields = [ "Max( version_number ) as version_number" ]
		);

		return Val( latestVersion.version_number ) + 1;
	}

	private void function _setupFirstVersionForAssetIfNoActiveVersion( required string assetId ) {
		var asset = getAsset( id=arguments.assetId, throwOnMissing=true, selectFields=[
			  "storage_path"
			, "size"
			, "asset_type"
			, "active_version"
			, "raw_text_content"
			, "created_by"
			, "updated_by"
		] );

		if ( !Len( Trim( asset.active_version ) ) ) {
			var versionId = _getAssetVersionDao().insertData( {
				  asset            = arguments.assetId
				, version_number   = 1
				, storage_path     = asset.storage_path
				, size             = asset.size
				, asset_type       = asset.asset_type
				, raw_text_content = asset.raw_text_content
				, created_by       = asset.created_by
				, updated_by       = asset.updated_by
			} );

			_getAssetDao().updateData( id=arguments.assetId, data={ active_version=versionId } );
		}
	}

	private struct function _getImageInfo( fileBinary ) {
		try {
			var info = ImageInfo( arguments.fileBinary );
			return {
				  width  = Val( info.width  ?: 0 )
				, height = Val( info.height ?: 0 )
			};
		} catch ( any e ) {
			return {};
		}
	}

	private any function _getStorageProviderForFolder( required string folderId ) {
		var location = _getStorageLocationForFolder( arguments.folderId );

		if ( location.isEmpty() ) {
			return _getDefaultStorageProvider();
		}

		return _getStorageProviderService().getProvider(
			  id            = location.storageProvider
			, configuration = location.configuration
		);
	}

	private struct function _getStorageLocationForFolder( required string folderId ){
		var folder = _getFolderDao().selectData(
			  id           = arguments.folderId
			, selectFields = [ "parent_folder", "storage_location" ]
		);

		if ( folder.recordCount ) {
			if ( folder.storage_location.len() ) {
				return _getStorageLocationService().getLocation( folder.storage_location );
			}
			if ( folder.parent_folder.len() ) {
				return _getStorageLocationForFolder( folder.parent_folder );
			}
		}

		return {};
	}

	private void function _deleteAssociatedFiles( required string assetId, required string folderId, string versionId="", boolean softDelete=false ) {
		var versionFilter    = { asset = arguments.assetId };
		var derivativeFilter = { asset = arguments.assetId };
		var assetVersionDao  = _getAssetVersionDao();
		var derivativeDao    = _getDerivativeDao();
		var trashedPath      = "";

		if ( arguments.versionId.len() ) {
			versionFilter.id               = arguments.versionId;
			derivativeFilter.asset_version = arguments.versionId;
		}

		if ( arguments.softDelete ) {
			versionFilter.is_trashed = false;
			derivativeFilter.is_trashed = false;
		}

		var versions        = assetVersionDao.selectData( filter=versionFilter   , selectfields=[ "id", "storage_path" ] );
		var derivatives     = derivativeDao.selectData( filter=derivativeFilter, selectfields=[ "id", "storage_path" ] );
		var storageProvider = _getStorageProviderForFolder( arguments.folderId );

		for( var version in versions ) {
			if ( arguments.softDelete ) {
				trashedPath = storageProvider.softDeleteObject( version.storage_path );
				assetVersionDao.updateData( id=version.id, data={ is_trashed=true, trashed_path=trashedPath } );
			} else {
				storageProvider.deleteObject( version.storage_path );
			}
		}
		for( var derivative in derivatives ) {
			if ( arguments.softDelete ) {
				trashedPath = storageProvider.softDeleteObject( derivative.storage_path );
				derivativeDao.updateData( id=derivative.id, data={ is_trashed=true, trashed_path=trashedPath } );
			} else {
				storageProvider.deleteObject( derivative.storage_path );
			}
		}
	}

	private void function _restoreAssociatedFiles( required string assetId, required any storageProvider ) {
		var assetVersionDao  = _getAssetVersionDao();
		var derivativeDao    = _getDerivativeDao();
		var versions         = assetVersionDao.selectData( filter={ asset=arguments.assetId, is_trashed=true }   , selectfields=[ "id", "storage_path", "trashed_path" ] );
		var derivatives      = derivativeDao.selectData( filter={ asset=arguments.assetId, is_trashed=true }, selectfields=[ "id", "storage_path", "trashed_path" ] );

		for( var version in versions ) {
			storageProvider.restoreObject( version.trashed_path, version.storage_path );
			assetVersionDao.updateData( id=version.id, data={ is_trashed=false, trashed_path="" } );
		}
		for( var derivative in derivatives ) {
			storageProvider.restoreObject( derivative.trashed_path, derivative.storage_path );
			derivativeDao.updateData( id=derivative.id, data={ is_trashed=false, trashed_path="" } );
		}
	}

// GETTERS AND SETTERS
	private any function _getDefaultStorageProvider() {
		return _defaultStorageProvider;
	}
	private void function _setDefaultStorageProvider( required any defaultStorageProvider ) {
		_defaultStorageProvider = arguments.defaultStorageProvider;
	}

	private any function _getTemporaryStorageProvider() {
		return _temporaryStorageProvider;
	}
	private void function _setTemporaryStorageProvider( required any temporaryStorageProvider ) {
		_temporaryStorageProvider = arguments.temporaryStorageProvider;
	}

	private any function _getAssetTransformer() {
		return _assetTransformer;
	}
	private void function _setAssetTransformer( required any assetTransformer ) {
		_assetTransformer = arguments.assetTransformer;
	}

	private struct function _getConfiguredDerivatives() {
		return _configuredDerivatives;
	}
	private void function _setConfiguredDerivatives( required struct configuredDerivatives ) {
		_configuredDerivatives = arguments.configuredDerivatives;
	}

	public string function getRootFolderId() {
		return _rootFolderId;
	}
	private void function _setRootFolderId( required string rootFolderId ) {
		_rootFolderId = arguments.rootFolderId;
	}

	private any function _getGroups() {
		return _groups;
	}
	private void function _setGroups( required any groups ) {
		_groups = arguments.groups;
	}

	private struct function _getTypes() {
		return _types;
	}
	private void function _setTypes( required struct types ) {
		_types = arguments.types;
	}

	private any function _getSystemConfigurationService() {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getAssetDao() {
		return _assetDao;
	}
	private void function _setAssetDao( required any assetDao ) {
		_assetDao = arguments.assetDao;
	}

	private any function _getAssetVersionDao() {
		return _assetVersionDao;
	}
	private void function _setAssetVersionDao( required any assetVersionDao ) {
		_assetVersionDao = arguments.assetVersionDao;
	}

	private any function _getFolderDao() {
		return _folderDao;
	}
	private void function _setFolderDao( required any folderDao ) {
		_folderDao = arguments.folderDao;
	}

	private any function _getDerivativeDao() {
		return _derivativeDao;
	}
	private void function _setDerivativeDao( required any derivativeDao ) {
		_derivativeDao = arguments.derivativeDao;
	}

	private any function _getAssetMetaDao() {
		return _assetMetaDao;
	}
	private void function _setAssetMetaDao( required any assetMetaDao ) {
		_assetMetaDao = arguments.assetMetaDao;
	}

	private any function _getDocumentMetadataService() {
		return _documentMetadataService;
	}
	private void function _setDocumentMetadataService( required any documentMetadataService ) {
		_documentMetadataService = arguments.documentMetadataService;
	}

	private any function _getStorageLocationService() {
		return _storageLocationService;
	}
	private void function _setStorageLocationService( required any storageLocationService ) {
		_storageLocationService = arguments.storageLocationService;
	}

	private any function _getStorageProviderService() {
		return _storageProviderService;
	}
	private void function _setStorageProviderService( required any storageProviderService ) {
		_storageProviderService = arguments.storageProviderService;
	}
}