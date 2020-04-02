/**
 * Provides APIs for programatically interacting with the Asset Manager (see [[assetmanager]] for more details)
 *
 * @singleton
 * @presideService
 * @autodoc
 */
component displayName="AssetManager Service" {

// CONSTRUCTOR
	/**
	 * @defaultStorageProvider.inject     assetStorageProvider
	 * @documentMetadataService.inject    DocumentMetadataService
	 * @storageLocationService.inject     storageLocationService
	 * @storageProviderService.inject     storageProviderService
	 * @assetQueueService.inject          presidecms:dynamicservice:assetQueue
	 * @derivativeGeneratorService.inject presidecms:dynamicservice:derivativeGenerator
	 * @configuredDerivatives.inject      coldbox:setting:assetManager.derivatives
	 * @configuredTypesByGroup.inject     coldbox:setting:assetManager.types
	 * @configuredFolders.inject          coldbox:setting:assetManager.folders
	 * @derivativeLimits.inject           coldbox:setting:assetManager.derivativeLimits
	 * @renderedAssetCache.inject         cachebox:renderedAssetCache
	 */
	public any function init(
		  required any    defaultStorageProvider
		, required any    documentMetadataService
		, required any    storageLocationService
		, required any    storageProviderService
		, required any    assetQueueService
		, required any    derivativeGeneratorService
		, required any    renderedAssetCache
		,          struct configuredDerivatives  = {}
		,          struct configuredTypesByGroup = {}
		,          struct derivativeLimits       = {}
		,          struct configuredFolders      = {}
	) {
		_migrateFromLegacyRecycleBinApproach();
		_setupSystemFolders( arguments.configuredFolders );

		_setDefaultStorageProvider( arguments.defaultStorageProvider );
		_setDocumentMetadataService( arguments.documentMetadataService );
		_setStorageLocationService( arguments.storageLocationService );
		_setStorageProviderService( arguments.storageProviderService );
		_setAssetQueueService( arguments.assetQueueService );
		_setDerivativeGeneratorService( arguments.derivativeGeneratorService );
		_setRenderedAssetCache( arguments.renderedAssetCache );
		_setDerivativeLimits( arguments.derivativeLimits );

		_setConfiguredDerivatives( arguments.configuredDerivatives );
		_setupConfiguredFileTypesAndGroups( arguments.configuredTypesByGroup );

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

		var auditDetail = Duplicate( arguments );
		auditDetail.id = _getFolderDao().insertData( data=arguments, insertManyToManyRecords=true );

		$audit(
			  action   = "add_folder"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		return auditDetail.id;
	}

	public boolean function editFolder( required string id, required struct data ) {
		if ( StructKeyExists( arguments.data, "parent_folder" ) && not Len( Trim( arguments.data.parent_folder ) ) ) {
			arguments.data.parent_folder = getRootFolderId();
		}

		var folder = getFolder( arguments.id );
		var result = _getFolderDao().updateData(
			  id                      = arguments.id
			, data                    = arguments.data
			, updateManyToManyRecords = true
		);

		if ( StructKeyExists( data, "access_restriction" ) && folder.access_restriction != arguments.data.access_restriction ) {
			$createTask(
				  event             = "admin.AssetManager._editAssetLocationInBackgroundThread"
				, args              = { id = arguments.id }
				, runNow            = true
				, adminOwner        = $getAdminLoggedInUserId()
				, discardOnComplete = false
				, title             = "cms:assetmanager.edit.folder.task.title"
			);
		}

		var auditDetail = Duplicate( arguments.data );
		auditDetail.id  = arguments.id;
		$audit(
			  action   = "edit_folder"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		return result;
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

		if ( arguments.includeChildFolder ) {
			ancestorArray.append( folder );
		}

		while( folder.recordCount ) {
			if ( not Len( Trim( folder.parent_folder ) ) ) {
				break;
			}
			folder = getFolder( id=folder.parent_folder );
			if( ancestorArray.indexOf(folder) >= 0 ) break;
			if ( folder.recordCount ) {
				ancestorArray.append( folder );
			}
		}

		for( var i=1; i <= ancestorArray.len(); i++ ) {
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
				if ( !StructKeyExists( collectedSettings, setting ) && Len( Trim( folder[ setting ] ?: "" ) ) ) {
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
		var folderSettings = getCascadingFolderSettings( id=arguments.id, settings=[ "allowed_filetypes", "max_filesize_in_mb", "min_width_in_px", "max_width_in_px", "min_height_in_px", "max_height_in_px" ] );

		folderSettings.allowed_filetypes  = ListToArray( folderSettings.allowed_filetypes ?: "" );
		folderSettings.max_filesize_in_mb = folderSettings.max_filesize_in_mb ?: "";
		folderSettings.min_width_in_px    = folderSettings.min_width_in_px    ?: "";
		folderSettings.max_width_in_px    = folderSettings.max_width_in_px    ?: "";
		folderSettings.min_height_in_px   = folderSettings.min_height_in_px   ?: "";
		folderSettings.max_height_in_px   = folderSettings.max_height_in_px   ?: "";

		if ( folderSettings.allowed_filetypes.len() ) {
			folderSettings.allowed_filetypes = expandTypeList( folderSettings.allowed_filetypes, true );
		}

		return {
			  allowedExtensions = ArrayToList( folderSettings.allowed_filetypes )
			, maxFileSize       = IsNumeric( folderSettings.max_filesize_in_mb ) ? folderSettings.max_filesize_in_mb : 10
			, minImageWidth     = IsNumeric( folderSettings.min_width_in_px )    ? folderSettings.min_width_in_px    : 0
			, maxImageWidth     = IsNumeric( folderSettings.max_width_in_px )    ? folderSettings.max_width_in_px    : 0
			, minImageHeight    = IsNumeric( folderSettings.min_height_in_px )   ? folderSettings.min_height_in_px   : 0
			, maxImageHeight    = IsNumeric( folderSettings.max_height_in_px )   ? folderSettings.max_height_in_px   : 0
		};
	}

	public boolean function areAssetsAllowedInFolder(
		  required array   assetIds
		, required string  folderId
		,          boolean throwIfNot = false
		,          boolean restore    = false
	) {
		var restrictions = getFolderRestrictions( arguments.folderId );
		var assets       = _getAssetDao().selectData(
			  filter       = { id = arguments.assetIds }
			, selectFields = [ "asset_type", "size", "asset_folder", "title", "original_title" ]
		);

		for( var asset in assets ) {
			var allowed = isAssetAllowedInFolder(
				  type            = asset.asset_type
				, size            = asset.size
				, currentFolderId = asset.asset_folder
				, folderId        = arguments.folderId
				, title           = asset.title
				, throwIfNot      = arguments.throwIfNot
				, restore         = arguments.restore
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
		,          string  title           = ""
		,          boolean throwIfNot      = false
		,          boolean restore         = false
		,          string  fileWidth       = 0
		,          string  fileHeight      = 0
		,          struct  restrictions    = getFolderRestrictions( arguments.folderId )
	) {
		var typeDisallowed  = restrictions.allowedExtensions.len() && !ListFindNoCase( restrictions.allowedExtensions, "." & arguments.type );
		var sizeInMb        = arguments.size / 1048576;
		var tooBig          = restrictions.maxFileSize && sizeInMb > restrictions.maxFileSize;
		var tooSmallWidth   = restrictions.minImageWidth  && val( arguments.fileWidth  ) && val( restrictions.minImageWidth  ) && arguments.fileWidth  < restrictions.minImageWidth;
		var tooBigWidth     = restrictions.maxImageWidth  && val( arguments.fileWidth  ) && val( restrictions.maxImageWidth  ) && arguments.fileWidth  > restrictions.maxImageWidth;
		var tooSmallHeight  = restrictions.minImageHeight && val( arguments.fileHeight ) && val( restrictions.minImageHeight ) && arguments.fileHeight < restrictions.minImageHeight;
		var tooBigHeight    = restrictions.maxImageHeight && val( arguments.fileHeight ) && val( restrictions.maxImageHeight ) && arguments.fileHeight > restrictions.maxImageHeight;
		var fileExist       = _getAssetDao().dataExists( filter={ title=arguments.title, asset_folder=arguments.folderId } );

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

		if ( tooSmallWidth ||  tooSmallHeight ) {
			if ( arguments.throwIfNot ) {
				throw(
					  type    = "PresideCMS.Assetmanager.asset.too.small.resolution.for.folder"
					, message = "Cannot add file to asset folder due to image resolution. Resolution of file: [#arguments.fileWidth#X#arguments.fileHeight# pixels]. Minimum resolution: [#restrictions.minImageWidth#X#restrictions.minImageHeight# pixels]."
				);
			}

			return false;
		}

		if ( tooBigWidth ||  tooBigHeight ) {
			if ( arguments.throwIfNot ) {
				throw(
					  type    = "PresideCMS.Assetmanager.asset.too.big.resolution.for.folder"
					, message = "Cannot add file to asset folder due to image resolution. Resolution of file: [#arguments.fileWidth#X#arguments.fileHeight# pixels]. Maximum resolution: [#restrictions.maxImageWidth#X#restrictions.maxImageHeight# pixels]."
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

		if ( fileExist && !arguments.restore ) {
			if ( arguments.throwIfNot ) {
				throw(
					  type    = "PresideCMS.AssetManager.asset.file.exist.in.folder"
					, message = "Cannot add file to asset folder due file already existing in the folder."
				);
			}

			return false;
		}

		return true;
	}

	public any function getFoldersForSelectList(
		  numeric maxRows            = 1000
		, string  searchQuery        = ""
		, array   ids                = []
		, string  excludeDescendants = ""
		, string  parentFolder
		, array   noPermissionFolders
	) {
		var rootFolderId         = getRootFolderId();
		var foldersForSelectList = [];
		var noPermissionFolders  = arguments.noPermissionFolders ?: _userNoPermissionAssetFolders();
		var filter               = "asset_folder.is_trashed = :is_trashed and ( asset_folder.hidden = :asset_folder.hidden or asset_folder.hidden is null )";
		var params               = {
			  is_trashed            = false
			, "asset_folder.hidden" = false
		}

		if( arrayLen( noPermissionFolders ) ) {
			filter &= " and ( asset_folder.id not in (:asset_folder.id) )";
			params[ "asset_folder.id" ] = noPermissionFolders;
		}

		var folders = _getFolderDao().selectData(
			  selectFields = [ "id", "label", "child_folders.id AS child_id" ]
			, orderBy      = "label"
			, filter       = filter
			, filterParams = params
		);

		// DATA PRE-PROCESSING
		// Converting it into a struct with the folder ID as key for easy access.
		var folderStruct = structNew( "ordered" );

		for( var row in folders ) {
			if( row.id == rootFolderId ) {
				row.label = $translateResource( "cms:assetmanager.root.folder", "" );
			}
			if( !structKeyExists( folderStruct, row.id ) ) {
				folderStruct[row.id] = { label=row.label, children=[] };
			}
			if( !Len( row.child_id) ) {
				continue;
			}
			folderStruct[row.id].children.prepend(row.child_id);
		}

		// DFS traversal down the trie.
		var parentFolderId = arguments.parentFolder ?: rootFolderId
		var folderQueue    = [ parentFolderId ];
		var visitedNodes   = [];
		var folderPassesCriteria = function( id, label ) {
			return ( !ids.len() || ids.findNoCase( arguments.id ) ) && ( !Len( Trim( searchQuery ) ) || arguments.label.findNoCase( searchQuery ) );
		};

		while( !folderQueue.isEmpty() ) {
			if( len(foldersForSelectList) >= arguments.maxRows ) break;

			var currentFolderId = folderQueue[ 1 ];
			var currentFolder   = folderStruct[ currentFolderId ];

			if( currentFolderId == arguments.excludeDescendants || visitedNodes.find( currentFolderId ) ) {
				folderQueue.deleteAt( 1 );
				continue;
			};

			if( folderPassesCriteria( currentFolderId, currentFolder.label ) ) {
				foldersForSelectList.append( { text=currentFolder.label, value=currentFolderId } );
			}

			var addedChildrenCount = 0;
			for( var child in currentFolder.children ) {
				if ( StructKeyExists( folderStruct, child ) && StructCount( folderStruct[ child ] ) )  {
					var parentLabel = ( currentFolderId == rootFolderId ) ? "" : currentFolder.label;

					folderStruct[ child ].label = trim( parentLabel & " / " & folderStruct[ child ].label );
					folderQueue.prepend( child );
					addedChildrenCount++;
				}
			}

			folderQueue.deleteAt( addedChildrenCount + 1 );
			visitedNodes.append( currentFolderId );
		}

		return foldersForSelectList;
	}

	public string function getAssetFolderPrefetchCachebusterForAjaxSelect() {
		var folders     = _getFolderDao().selectData(
			selectFields = [ "Max( datemodified ) as lastmodified" ]
		);
		var permissions = $getPresideObject( "security_context_permission" ).selectData(
			  filter       = { context="assetmanagerfolder" }
			, selectFields = [ "Max( datemodified ) as lastmodified" ]
		);
		var lastUpdate  = IsDate( folders.lastmodified ) ? folders.lastmodified : now();
		if ( IsDate( permissions.lastmodified ) ) {
			lastUpdate = max( lastUpdate, permissions.lastmodified );
		}

		return Hash( lastUpdate );
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
			, autoGroupBy  = true
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
			if ( StructKeyExists( types, typeName ) ) {
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
		, string  orderBy     = "datecreated DESC"
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
			, selectFields = [ "id", "asset_folder", "#titleField# as title", "asset_type", "datemodified", "datecreated" ]
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

	public array function searchAssets( array ids=[], string searchQuery="", array allowedTypes=[], numeric maxRows=100, string savedFilters="" ) {
		var assetDao            = _getAssetDao();
		var filter              = "( asset.is_trashed = :is_trashed and asset_folder.hidden = :asset_folder.hidden )";
		var params              = { is_trashed=false, "asset_folder.hidden"=false };
		var types               = _getTypes();
		var records             = "";
		var result              = [];
		var noPermissionFolders = _userNoPermissionAssetFolders();

		if ( arguments.ids.len() ) {
			filter &= " and ( asset.id in (:id) )";
			params.id = arguments.ids;
		}
		if ( arguments.allowedTypes.len() ) {
			params.asset_type = [];

			for( var typeName in expandTypeList( arguments.allowedTypes ) ){
				params.asset_type.append( typeName );
			}
			if ( params.asset_type.len() ){
				filter &= " and ( asset.asset_type in (:asset_type) )";
			} else {
				params.delete( "asset_type" );
			}
		}
		if ( Len( Trim( arguments.searchQuery ) ) ) {
			filter &= " and ( asset.title like (:title) or asset_folder.label like (:title) )";
			params.title = "%#arguments.searchQuery#%";
		}
		if( arrayLen( noPermissionFolders ) ){
			filter &= " and ( asset.asset_folder not in (:asset_folder.id) )";
			params[ "asset_folder.id" ] = noPermissionFolders;
		}

		records = assetDao.selectData(
			  selectFields = [ "asset.id as value", "asset.${labelfield} as text", "asset_folder.${labelfield} as folder", "asset.width", "asset.height" ]
			, filter       = filter
			, filterParams = params
			, savedFilters = ListToArray( arguments.savedFilters )
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

		var result = _getFolderDao().updateData( id = arguments.id, data = {
			  is_trashed     = true
			, label          = CreateUUId()
			, original_label = folder.label
		} );

		for( var f in folder ) { var auditDetail = f; }
		$audit(
			  action   = "trash_folder"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		return result;
	}

	/**
	 * Adds an asset into the Asset manager. The asset binary will be uploaded to the appropriate storage
	 * location for the given folder.
	 *
	 * @autodoc
	 * @fileBinary.hint        Binary data of the file
	 * @fileName.hint          Uploaded filename (asset type information will be retrieved from here)
	 * @folder.hint            Either folder ID or name of a configured system folder
	 * @assetData.hint         Structure of additional data that can be saved against the [[presideobject-asset]] record
	 * @ensureUniqueTitle.hint If set to true (default is false), asset titles will be made unique should name conflicts exist
	 *
	 */
	public string function addAsset(
		  required binary  fileBinary
		, required string  fileName
		, required string  folder
		,          struct  assetData         = {}
		,          boolean ensureUniqueTitle = false
	) {
		var fileTypeInfo = getAssetType( filename=arguments.fileName, throwOnMissing=true );
		var asset        = Duplicate( arguments.assetData );
		var fileMetaInfo = _getDocumentMetadataService().getMetaData( arguments.fileBinary );
		var fileWidth    = fileMetaInfo.width  ?: 0;
		var fileHeight   = fileMetaInfo.height ?: 0;

		asset.id               = CreateUUId();
		asset.asset_folder     = resolveFolderId( arguments.folder );
		asset.asset_type       = fileTypeInfo.typeName;
		asset.size             = asset.size  ?: Len( arguments.fileBinary );
		asset.title            = asset.title ?: arguments.fileName;
		asset.file_name        = asset.file_name ?: _slugifyTitleForFileName( asset.title );
		asset.storage_path     = "/#LCase( asset.id )#/#asset.file_name#.#fileTypeInfo.extension#";

		isAssetAllowedInFolder(
			  type       = asset.asset_type
			, size       = asset.size
			, folderId   = asset.asset_folder
			, throwIfNot = true
			, fileWidth  = fileWidth
			, fileHeight = fileHeight
		);

		if ( arguments.ensureUniqueTitle ) {
			asset.title = _ensureUniqueTitle( asset.title, asset.asset_folder );
		}

		getStorageProviderForFolder( asset.asset_folder ).putObject(
			  object  = arguments.fileBinary
			, path    = asset.storage_path
			, private = isFolderAccessRestricted( asset.asset_folder )
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

		_getAssetDao().insertData( data=asset, insertManyToManyRecords=true );

		if ( _autoExtractDocumentMeta() ) {
			_saveAssetMetaData( assetId=asset.id, metaData=fileMetaInfo );
		}

		_autoQueueDerivatives( asset.id, fileTypeInfo.typeName, fileTypeInfo.groupName );

		$audit(
			  action   = "add_asset"
			, type     = "assetmanager"
			, detail   = asset
			, recordId = asset.id
		);

		return asset.id;
	}

	public boolean function addAssetVersion( required string assetId, required binary fileBinary, required string fileName, boolean makeActive=true  ) {
		var originalAsset = getAsset( id=arguments.assetId, selectFields=[ "id", "title", "file_name", "asset_type", "asset_folder", "focal_point", "crop_hint", "access_restriction" ] );

		if( !originalAsset.recordCount ) {
			return false;
		}

		var originalFileTypeInfo = getAssetType( name=originalAsset.asset_type, throwOnMissing=true );
		var fileTypeInfo         = getAssetType( filename=arguments.fileName, throwOnMissing=true );

		if ( fileTypeInfo.mimeType != originalFileTypeInfo.mimeType ) {
			throw( type="AssetManager.mismatchedMimeType", message="The mime type of the uploaded file, [#fileTypeInfo.mimeType#], does not match that of the original version [#originalFileTypeInfo.mimeType#]." );
		}

		var versionId    = CreateUUId();
		var fileName     = Len( Trim( originalAsset.file_name ) ) ? originalAsset.file_name : _slugifyTitleForFileName( originalAsset.title );
		var newFileName  = "/#LCase( arguments.assetId )#/#LCase( versionId )#/#fileName#.#fileTypeInfo.extension#";
		var assetVersion = {
			  id             = versionId
			, asset          = arguments.assetId
			, asset_type     = fileTypeInfo.typeName
			, storage_path   = newFileName
			, size           = Len( arguments.fileBinary )
			, focal_point    = originalAsset.focal_point
			, crop_hint      = originalAsset.crop_hint
			, version_number = _getNextAssetVersionNumber( arguments.assetId )
		};

		if ( _autoExtractDocumentMeta() ) {
			assetVersion.raw_text_content = _getDocumentMetadataService().getText( arguments.fileBinary );
		}

		getStorageProviderForFolder( originalAsset.asset_folder ).putObject(
			  object  = arguments.fileBinary
			, path    = newFileName
			, private = originalAsset.access_restriction == "full" || isFolderAccessRestricted( originalAsset.asset_folder )
		);

		_getAssetVersionDao().insertData( data=assetVersion );

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

		invalidateRenderedAssetCache( arguments.assetId );

		_autoQueueDerivatives( arguments.assetId, fileTypeInfo.typeName, fileTypeInfo.groupName, versionId );

		var auditDetail = assetVersion;
		for( var a in originalAsset ) { auditDetail.append( a ); }
		$audit(
			  action   = "add_asset_version"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

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
			if ( !IsNull( local.fileBinary ) ) {
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
		var asset       = getAsset( id=arguments.id );
		var result      = _getAssetDao().updateData( id=arguments.id, data=arguments.data, updateManyToManyRecords=true );
		var auditDetail = Duplicate( arguments.data );
		var fileNameChanged = StructKeyExists( arguments.data, "file_name" ) && Compare( asset.file_name, arguments.data.file_name );
		var updateData  = {};

		if ( fileNameChanged ) {
			processFileNameChange( arguments.id, arguments.data.file_name );
		}

		if ( len( asset.active_version ) ) {
			if ( StructKeyExists( data, "focal_point") ) {
				updateData.focal_point=data.focal_point;
			}
			if ( StructKeyExists( data, "crop_hint") ) {
				updateData.crop_hint=data.crop_hint;
			}
			if ( !updateData.isEmpty() ) {
				_getAssetVersionDao().updateData( id=asset.active_version, data=updateData )
			}
		}

		if ( StructKeyExists( data, "access_restriction" ) && asset.access_restriction != arguments.data.access_restriction ) {
			ensureAssetsAreInCorrectLocation( assetId=arguments.id );
		}

		flushAssetUrlCache( arguments.id );
		invalidateRenderedAssetCache( arguments.id );

		if ( !updateData.isEmpty() ) {
			var fileTypeInfo  = getAssetType( name=asset.asset_type, throwOnMissing=true );
			_autoQueueDerivatives( arguments.id, fileTypeInfo.typeName, fileTypeInfo.groupName, asset.active_version );
		}

		auditDetail.id = arguments.id;
		$audit(
			  action   = "edit_asset"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = arguments.id
		);

		return result;
	}

	public void function processFileNameChange( required string id, required string newName ) {
		var asset = getAsset( id=arguments.id );
		if ( !asset.recordCount ) {
			return;
		}

		for( var a in asset ) { asset = a; }

		var assetDao      = _getAssetDao();
		var derivativeDao = _getDerivativeDao();
		var versionDao    = _getAssetVersionDao();
		var derivatives   = derivativeDao.selectData( filter={ asset=arguments.id } );
		var versions      = versionDao.selectData( filter={ asset=arguments.id } );
		var filename      = arguments.newName;
		var isPrivate     = isAssetAccessRestricted( arguments.id );
		var provider      = getStorageProviderForFolder( asset.asset_folder );

		filename = filename.reReplaceNoCase( "\.#asset.asset_type#$", "" );

		// move the asset itself
		var oldStoragePath = asset.storage_path;
		var newStoragePath = "/#LCase( asset.id )#/#filename#.#asset.asset_type#";

		provider.moveObject(
			  originalPath      = oldStoragePath
			, newPath           = newStoragePath
			, originalIsPrivate = isPrivate
			, newIsPrivate      = isPrivate
		);

		assetDao.updateData( id=arguments.id, data={
			  storage_path = newStoragePath
			, asset_url    = ""
		} );

		if ( Len( Trim( asset.active_version ) ) ){
			versionDao.updateData( id=asset.active_version, data={
				  storage_path = newStoragePath
				, asset_url    = ""
			} );
		}

		// move versions
		for( var version in versions ) {
			if ( version.id == asset.active_version ) {
				continue;
			}

			oldStoragePath = version.storage_path;
			newStoragePath = "/#LCase( asset.id )#/#LCase( version.id )#/#filename#.#version.asset_type#";

			provider.moveObject(
				  originalPath      = oldStoragePath
				, newPath           = newStoragePath
				, originalIsPrivate = isPrivate
				, newIsPrivate      = isPrivate
			);

			versionDao.updateData( id=version.id, data={
				  storage_path = newStoragePath
				, asset_url    = ""
			} );
		}

		// move derivatives
		if ( derivatives.recordCount ) {
			var config          = getDerivativeConfig( arguments.id );
			var configHash      = getDerivativeConfigHash( config );

			for( var derivative in derivatives ) {
				oldStoragePath = derivative.storage_path;
				newStoragePath = "/#LCase( asset.id )#";

				if ( Len( Trim( derivative.asset_version ) ) ) {
					newStoragePath &= "/#LCase( derivative.asset_version )#";
				}

				newStoragePath &= "/#LCase( derivative.label )#";
				if ( Len( Trim( configHash ) ) ) {
					newStoragePath &= "_#LCase( configHash )#";
				}
				newStoragePath &= "/#filename#.#derivative.asset_type#";

				provider.moveObject(
					  originalPath      = oldStoragePath
					, newPath           = newStoragePath
					, originalIsPrivate = isPrivate
					, newIsPrivate      = isPrivate
				);

				derivativeDao.updateData( id=derivative.id, data={
					  storage_path = newStoragePath
					, asset_url    = ""
				} );
			}
		}
	}

	public void function flushAssetUrlCache( required string assetId ) {
		_getAssetDao().updateData( id=arguments.assetId, data={ asset_url="" } );
		_getAssetVersionDao().updateData( filter={ asset=arguments.assetId }, data={ asset_url="" } );
		_getDerivativeDao().updateData( filter={ asset=arguments.assetId }, data={ asset_url="" } );
	}

	public boolean function moveAssets( required array assetIds, required string folderId ) {
		var folder = getFolder( arguments.folderId );
		if ( folder.recordCount ) {
			areAssetsAllowedInFolder(
				  assetIds   = arguments.assetIds
				, folderId   = arguments.folderId
				, throwIfNot = true
			);

			var result = _getAssetDao().updateData(
				  filter = { id = arguments.assetIds }
				, data   = { asset_folder = arguments.folderId }
			);

			ensureAssetsAreInCorrectLocation( assetIds=arguments.assetIds );

			$audit(
				  action = "move_assets"
				, type   = "assetmanager"
				, detail = arguments
			);

			return result;
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
				, restore    = true
			);

			for( var assetId in arguments.assetIds ) {
				var asset = getAsset( id=assetId, selectFields=[ "original_title", "file_name", "asset_type", "trashed_path", "asset_folder", "active_version" ] );
				if ( asset.recordCount ) {
					var fileName        = Len( Trim( asset.file_name ) ) ? asset.file_name : _slugifyTitleForFileName( asset.original_title );
					var newPath         = "/#LCase( assetId )#/#fileName#.#asset.asset_type#";
					var storageProvider = getStorageProviderForFolder( asset.asset_folder );
					var private         = isAssetAccessRestricted( assetId, arguments.folderId );

					storageProvider.restoreObject( trashedPath=asset.trashed_path, newPath=newPath, private=private );
					if ( Len( Trim( asset.active_version ) ) ) {
						_getAssetVersionDao().updateData( id=asset.active_version, data={
							  is_trashed     = false
							, storage_path   = newPath
							, trashed_path   = ""
							, asset_url      = ""
						} );
					}

					_restoreAssociatedFiles( assetId, storageProvider, private );

					restoredAssetCount += _getAssetDao().updateData( id=assetId, data={
						  asset_folder   = arguments.folderId
						, title          = _ensureUniqueTitle( asset.original_title, arguments.folderId )
						, is_trashed     = false
						, storage_path   = newPath
						, original_title = ""
						, asset_url      = ""
						, trashed_path   = ""
					} );


				}
			}

			if ( restoredAssetCount ) {
				$audit(
					  action = "restore_assets"
					, type   = "assetmanager"
					, detail = arguments
				);
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

	public binary function getAssetBinary(
		  required string  id
		,          string  versionId             = ""
		,          boolean throwOnMissing        = false
		,          boolean isTrashed             = false
		,          boolean placeholderIfTooLarge = false
	) {
		var assetBinary = "";
		var isPrivate   = isAssetAccessRestricted( arguments.id )
		var storagePathField = arguments.isTrashed ? "trashed_path as storage_path" : "storage_path";
		var asset       = Len( Trim( arguments.versionId ) )
			? getAssetVersion( assetId=arguments.id, versionId=arguments.versionId, throwOnMissing=arguments.throwOnMissing, selectFields=[ "asset_version.#storagePathField#", "asset.asset_folder", "asset.width", "asset.height" ] )
			: getAsset( id=arguments.id, throwOnMissing=arguments.throwOnMissing, selectFields=[ storagePathField, "asset_folder", "width", "height" ] );

		if ( asset.recordCount ) {
			if ( arguments.placeholderIfTooLarge && assetIsTooLargeForDerivatives( asset.width, asset.height ) ) {
				return _getLargeImagePlaceholder();
			}
			return getStorageProviderForFolder( asset.asset_folder ).getObject(
				  path    = asset.storage_path
				, trashed = arguments.isTrashed
				, private = isPrivate
			);
		}
	}

	public string function getAssetEtag( required string id, string derivativeName="", string versionId="", string configHash="", boolean throwOnMissing=false, boolean isTrashed=false ) {
		var asset            = "";
		var storagePathField = arguments.isTrashed ? "trashed_path as storage_path" : "storage_path";

		if ( Len( Trim( arguments.derivativeName ) ) ) {
			asset = getAssetDerivative(
				  assetId        = arguments.id
				, versionId      = arguments.versionId
				, configHash     = arguments.configHash
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
			var private   = Len( Trim( arguments.derivativeName ) ) ? ( !isDerivativePubliclyAccessible( arguments.derivativeName ) && isAssetAccessRestricted( arguments.id ) ) : isAssetAccessRestricted( arguments.id )
			var assetInfo = getStorageProviderForFolder( asset.asset_folder ).getObjectInfo(
				  path    = asset.storage_path
				, trashed = arguments.isTrashed
				, private = private
			);
			if ( arguments.configHash.len() ) {
				assetInfo.configHash = arguments.configHash;
			}
			var etag      = LCase( Hash( SerializeJson( assetInfo ) ) )

			return Left( etag, 8 );
		}

		return "";
	}

	public string function getAssetUrl( required string id, string versionId="", boolean trashed=false ) {
		var asset   = "";
		var version = arguments.versionId;

		if ( Len( Trim( version ) ) ) {
			asset = getAssetVersion( assetId=arguments.id, versionId=version, selectFields=[ "asset_version.storage_path", "asset.asset_folder", "asset_version.asset_url" ] );
		} else {
			asset   = getAsset( id=arguments.id, selectFields=[ "storage_path", "asset_folder", "asset_url", "active_version" ] );
			version = asset.active_version ?: "";
		}

		if ( !asset.recordCount ) {
			return "";
		}

		if ( Len( Trim( asset.asset_url ) ) ) {
			return asset.asset_url;
		}

		var generatedUrl = generateAssetUrl(
			  id          = arguments.id
			, versionId   = version
			, storagePath = asset.storage_path
			, folder      = asset.asset_folder
			, trashed     = arguments.trashed
		);

		if ( !Len( Trim( arguments.versionId ) ) ) {
			_getAssetDao().updateData( id=arguments.id, data={ asset_url = generatedUrl } );
		}
		if ( Len( Trim( version ) ) ) {
			_getAssetVersionDao().updateData( id=version, data={ asset_url = generatedUrl } );
		}

		return generatedUrl;
	}

	public string function getDerivativeUrl(
		  required string assetId
		, required string derivativeName
		,          string versionId  = ""
		,          string configHash
	) {
		var version    = Len( Trim( arguments.versionId ) ) ? arguments.versionId : getActiveAssetVersion( arguments.assetId );
		var configHash = arguments.configHash ?: getDerivativeConfigHash( getDerivativeConfig( arguments.assetId ) );
		var derivative = getAssetDerivative(
			  assetId           = arguments.assetId
			, derivativeName    = arguments.derivativeName
			, configHash        = configHash
			, selectFields      = [ "asset_derivative.id", "asset_derivative.asset_url", "asset_derivative.storage_path", "asset.asset_folder", "asset.active_version" ]
			, versionId         = version
			, createIfNotExists = false
		);

		if ( !derivative.recordCount ) {
			if ( $isFeatureEnabled( "assetQueue" ) ) {
				_getAssetQueueService().queueAssetGeneration(
					  assetId        = arguments.assetId
					, derivativeName = arguments.derivativeName
					, versionId      = arguments.versionId
					, configHash     = arguments.configHash ?: ""
				);
			}

			return getInternalAssetUrl(
				  id         = arguments.assetId
				, versionId  = version
				, derivative = arguments.derivativeName
				, trashed    = false
			);
		}

		if ( Len( Trim( derivative.asset_url ) ) ) {
			return derivative.asset_url;
		}

		var generatedUrl = generateAssetUrl(
			  id          = arguments.assetId
			, versionId   = version
			, storagePath = derivative.storage_path
			, folder      = derivative.asset_folder
			, derivative  = arguments.derivativeName
		);

		_getDerivativeDao().updateData( id=derivative.id, data={ asset_url = generatedUrl } );

		return generatedUrl;
	}

	public string function getActiveAssetVersion( required string id ) {
		var record = _getAssetDao().selectData( id=arguments.id, selectfields=[ "active_version" ] );

		return record.active_version ?: "";
	}

	public string function generateAssetUrl(
		  required string  id
		, required string  storagePath
		, required string  folder
		,          string  versionId  = ""
		,          string  derivative = ""
		,          boolean trashed    = false
	) {
		if ( !arguments.trashed ) {
			if ( Len( Trim( arguments.derivative ) ) && isDerivativePubliclyAccessible( arguments.derivative ) ) {
				var permissions = { restricted = false }
			} else {
				var permissions = getAssetPermissioningSettings( arguments.id );
			}

			if ( !permissions.restricted ) {
				var storageProvider = getStorageProviderForFolder( arguments.folder );
				var assetUrl        = storageProvider.getObjectUrl( arguments.storagePath );

				if ( Len( Trim( assetUrl ) ) ) {
					return assetUrl;
				}
			}
		}

		return getInternalAssetUrl(
			  id         = arguments.id
			, versionId  = arguments.versionId
			, trashed    = arguments.trashed
			, derivative = arguments.derivative
		);
	}

	public string function getInternalAssetUrl( required string id, string versionId="", string derivative="", boolean trashed=false ) {
		var internalUrl = "/asset/";

		if ( arguments.trashed ) {
			internalUrl &= "$";
		}

		internalUrl &= UrlEncodedFormat( arguments.id );

		if ( Len( Trim( arguments.versionId ) ) ) {
			internalUrl &= "." & UrlEncodedFormat( arguments.versionId );
		}

		internalUrl &= "/";

		if ( Len( Trim( arguments.derivative ) ) ) {
			internalUrl &= UrlEncodedFormat( arguments.derivative ) & "/";
			var signature = getDerivativeConfigSignature( arguments.derivative );
			if ( Len( Trim( signature ) ) ) {
				internalUrl &= UrlEncodedFormat( signature ) & "/";
			}
		}

		return internalUrl;
	}

	public boolean function trashAsset( required string id ) {
		var assetDao    = _getAssetDao();
		var asset       = assetDao.selectData( id=arguments.id, selectFields=[ "id", "storage_path", "title", "asset_folder", "active_version" ] );
		var private     = isAssetAccessRestricted( arguments.id );
		var trashedPath = "";

		if ( !asset.recordCount ) {
			return false;
		}

		try {
			trashedPath = getStorageProviderForFolder( asset.asset_folder ).softDeleteObject( path=asset.storage_path, private=private );
		} catch( any e ) {
			$raiseError( e );
			trashedPath = asset.storage_path;
		}

		if( asset.active_version.len() ) {
			_getAssetVersionDao().updateData(
				  id   = asset.active_version
				, data = { is_trashed=true, trashed_path = trashedPath, asset_url="" }
			);
		}

		try {
			_deleteAssociatedFiles(
				  assetId    = arguments.id
				, folderId   = asset.asset_folder
				, softDelete = true
				, private    = private
			);
		} catch( any e ) {
			// ignore errors due to missing files
			$raiseError( e );
		}

		var result = assetDao.updateData( id=arguments.id, data={
			  trashed_path   = trashedPath
			, title          = CreateUUId()
			, original_title = asset.title
			, is_trashed     = true
			, asset_url      = ""
		} );

		for( var a in asset ) { var auditDetail = a; }
		$audit(
			  action   = "trash_asset"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		return result;
	}

	public boolean function permanentlyDeleteAsset( required string id ) {
		var assetDao    = _getAssetDao();
		var asset       = assetDao.selectData( id=arguments.id, selectFields=[ "id", "trashed_path", "title", "asset_folder" ] );
		var trashedPath = "";

		if ( !asset.recordCount ) {
			return false;
		}

		try {
			getStorageProviderForFolder( asset.asset_folder ).deleteObject( asset.trashed_path, true );
		} catch( any e ) {
			$raiseError( e );
		}
		try {
			_deleteAssociatedFiles( arguments.id, asset.asset_folder );
		} catch( any e ) {
			$raiseError( e );
		}

		for( var a in asset ) { var auditDetail = a; }
		$audit(
			  action   = "permanently_delete_asset"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		return assetDao.deleteData( id=arguments.id );
	}

	public boolean function clearAssetDerivatives( required any assetIds ) {
		var assetDao      = _getAssetDao();
		var derivativeDao = _getDerivativeDao();
		var asset         = assetDao.selectData( filter={ id=arguments.assetIds }, selectFields=[ "id", "asset_folder" ] );

		if ( !asset.recordCount ) {
			return false;
		}

		return derivativeDao.deleteData( filter={ asset=arguments.assetIds } );
	}

	public boolean function clearFolderDerivatives( required string folderId ) {
		var derivativeDao = _getDerivativeDao();

		return derivativeDao.deleteData( filter={ "asset.asset_folder"=arguments.folderId } );
	}

	public query function getAssetDerivative(
		  required string  assetId
		, required string  derivativeName
		,          string  versionId         = ""
		,          string  configHash        = ""
		,          array   selectFields      = []
		,          boolean createIfNotExists = true
	) {
		var derivativeDao      = _getDerivativeDao();
		var signature          = getDerivativeConfigSignature( arguments.derivativeName );
		var derivative         = "";
		var derivativeId       = "";
		var lockName           = "getAssetDerivative( #arguments.assetId#, #arguments.derivativeName#, #arguments.versionId#, #arguments.configHash# )";
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

		if ( Len( Trim( arguments.configHash ) ) ) {
			selectFilter &= " and asset_derivative.config_hash = :asset_derivative.config_hash";
			selectFilterParams[ "asset_derivative.config_hash" ] = arguments.configHash;
		} else {
			selectFilter &= " and asset_derivative.config_hash is null";
		}

		arrayAppend( arguments.selectFields, "asset_derivative.retry_count" );

		for( var selectItem in [ "asset_derivative.id","asset_derivative.asset_type","asset_derivative.storage_path", "asset_derivative.datecreated" ] ){
			if( !arrayFind( arguments.selectFields, selectItem ) ){
				arrayAppend( arguments.selectFields, selectItem );
			}
		}

		derivative = derivativeDao.selectData( filter=selectFilter, filterParams=selectFilterParams, selectFields=arguments.selectFields );
		if ( derivative.recordCount ) {
			var isPending = _isPendingAssetURL( asset_url=derivative.asset_url ?: "", asset_type=derivative.asset_type ?: "", storage_path=derivative.storage_path ?: "" );
			if ( isPending ) {
				var shouldRetry = arguments.createIfNotExists && Val( derivative.retry_count ) < 3 && DateDiff( "s", derivative.datecreated, Now() ) > 20;
				if ( shouldRetry ) {
					_getDerivativeDao().updateData( id=derivative.id, data={ asset_url="", retry_count=Val( derivative.retry_count ?: "" ) + 1 } );
					createAssetDerivative( derivativeId=derivative.id, assetId=arguments.assetId, versionId=arguments.versionId, derivativeName=arguments.derivativeName );
					return derivativeDao.selectData( id=derivative.id, selectFields=arguments.selectFields, useCache=false );
				}

				return QueryNew( "" );
			} else {
				return derivative;
			}
		}

		if ( arguments.createIfNotExists ) {
			lock type="exclusive" name=lockName timeout=1 {
				derivative = derivativeDao.selectData( filter=selectFilter, filterParams=selectFilterParams, selectFields=arguments.selectFields, useCache=false );
				if ( derivative.recordCount ) {
					return derivative;
				}

				derivativeId = createAssetDerivativeRecord( assetId=arguments.assetId, versionId=arguments.versionId, derivativeName=arguments.derivativeName, configHash=arguments.configHash );
			}

			createAssetDerivative( derivativeId=derivativeId, assetId=arguments.assetId, versionId=arguments.versionId, derivativeName=arguments.derivativeName );

			return derivativeDao.selectData( filter=selectFilter, filterParams=selectFilterParams, selectFields=arguments.selectFields, useCache=false );
		}

		return QueryNew( '' );
	}

	public binary function getAssetDerivativeBinary( required string assetId, required string derivativeName, string versionId="", string configHash="" ) {
		var derivative = getAssetDerivative(
			  assetId        = arguments.assetId
			, derivativeName = arguments.derivativeName
			, versionId      = arguments.versionId
			, configHash     = arguments.configHash
			, selectFields   = [ "asset_derivative.storage_path", "asset.asset_folder" ]
		);

		if ( derivative.recordCount ) {
			return getStorageProviderForFolder( derivative.asset_folder ).getObject(
				  path    = derivative.storage_path
				, private = !isDerivativePubliclyAccessible( arguments.derivativeName ) && isAssetAccessRestricted( arguments.assetId )
			);
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

	public string function createAssetDerivativeRecord(
		  required string assetId
		, required string derivativeName
		,          string versionId      = ""
		,          string configHash
	) {
		var signature  = getDerivativeConfigSignature( arguments.derivativeName );
		var configHash = arguments.configHash ?: getDerivativeConfigHash( getDerivativeConfig( arguments.assetId ) );

		return _getDerivativeDao().insertData( {
			  asset         = arguments.assetId
			, asset_version = arguments.versionId
			, label         = arguments.derivativeName & signature
			, config_hash   = arguments.configHash
			, asset_type    = "PENDING"
			, storage_path  = "PENDING-" & CreateUUId()
		} );
	}

	public string function createAssetDerivative(
		  required string  assetId
		, required string  derivativeName
		,          string  versionId       = ""
		,          array   transformations = _getPreconfiguredDerivativeTransformations( arguments.derivativeName )
		,          string  derivativeId    = ""
		,          boolean forceIfExists  = false
	) {
		var signature  = getDerivativeConfigSignature( arguments.derivativeName )
		var config     = getDerivativeConfig( arguments.assetId )
		var configHash = getDerivativeConfigHash( config )
		var asset      = "";

		if ( Len( Trim( arguments.versionId ) ) ) {
			asset = getAssetVersion( assetId=arguments.assetId, versionId=arguments.versionId, throwOnMissing=true, selectFields=[ "asset_version.storage_path", "asset.asset_folder", "asset.file_name", "asset.title", "asset_version.focal_point", "asset_version.crop_hint" ] );
		} else {
			asset = getAsset( id=arguments.assetId, throwOnMissing=true, selectFields=[ "file_name", "title", "storage_path", "asset_folder", "focal_point", "crop_hint" ] );
		}

		var fileext         = ListLast( asset.storage_path, "." );
		var filename        = Len( Trim( asset.file_name ) ) ? asset.file_name : _slugifyTitleForFileName( asset.title );
		var derivativeSlug  = ReReplace( arguments.derivativeName, "\W", "_", "all" ) & "_" & signature;
		var storagePath     = "/#LCase( arguments.assetId )#";

		if ( Len( Trim( arguments.versionId ) ) ) {
			storagePath &= "/#LCase( arguments.versionId )#";
		}

		storagePath &= "/#LCase( derivativeSlug )#";
		if ( Len( Trim( configHash ) ) ) {
			storagePath &= "_#LCase( configHash )#";
		}
		storagePath &= "/#filename#.#fileext#";

		if ( !Len( Trim( arguments.derivativeId ) ) && arguments.forceIfExists ) {
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

			var derivative = derivativeDao.selectData( filter=selectFilter, filterParams=filterParams, selectFields=[ "id" ] );
			arguments.derivativeId = derivative.id ?: "";
		}

		return _getDerivativeGeneratorService().generate(
			  assetId                       = arguments.assetId
			, versionId                     = arguments.versionId
			, derivativeName                = arguments.derivativeName
			, transformations               = arguments.transformations
			, derivativeId                  = arguments.derivativeId
			, derivativeSignature           = signature
			, assetTransformationConfig     = config
			, assetTransformationConfigHash = configHash
			, asset                         = asset
			, storagePath                   = storagePath
		);
	}

	public struct function getAssetPermissioningSettings( required string assetId ) {
		var asset    = getAsset( arguments.assetId );
		var settings = {
			  contextTree                        = [ arguments.assetId ] //ListToArray( ValueList( folders.id ) ) };
			, restricted                         = false
			, fullLoginRequired                  = false
			, grantAcessToAllLoggedInUsers       = false
			, conditionId                        = ""
		}

		if ( !asset.recordCount ){ return settings; }

		var folders = getFolderAncestors( asset.asset_folder, true );

		for( var folder in folders ){ settings.contextTree.append( folder.id ); }

		if ( asset.access_restriction != "inherit" ) {
			settings.restricted                   = asset.access_restriction == "full";
			settings.fullLoginRequired            = IsBoolean( asset.full_login_required ) && asset.full_login_required;
			settings.grantAcessToAllLoggedInUsers = IsBoolean( asset.grantaccess_to_all_logged_in_users ) && asset.grantaccess_to_all_logged_in_users;
			settings.conditionId                  = asset.access_condition;

			return settings;
		}


		for( var folder in folders ) {
			if ( folder.access_restriction != "inherit" ) {
				settings.restricted                   = folder.access_restriction == "full";
				settings.fullLoginRequired            = IsBoolean( folder.full_login_required ) && folder.full_login_required;
				settings.grantAcessToAllLoggedInUsers = IsBoolean( folder.grantaccess_to_all_logged_in_users ) && folder.grantaccess_to_all_logged_in_users;
				settings.conditionId                  = folder.access_condition;

				return settings;
			}
		}

		return settings;
	}

	public boolean function isFolderAccessRestricted( required string folderId ) {
		var folders = getFolderAncestors( arguments.folderId, true );

		for( var folder in folders ) {
			if ( folder.access_restriction != "inherit" ) {
				return folder.access_restriction == "full";
			}
		}

		return false;
	}

	public boolean function isAssetAccessRestricted( required string id, string folderId ) {
		var asset = getAsset( id = arguments.id, selectFields=[ "asset_folder", "access_restriction" ] );

		if ( asset.recordCount ) {
			if ( asset.access_restriction != "inherit" ) {
				return asset.access_restriction == "full";
			}

			return isFolderAccessRestricted( arguments.folderId ?: asset.asset_folder );
		}

		return false;
	}

	public any function listEditorDerivatives(){
		var derivatives = _getConfiguredDerivatives();
		var publicDerivatives = [];

		for( var derivative in derivatives ) {
			if ( StructKeyExists( derivatives[ derivative ], "inEditor" ) ) {
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

		if ( StructKeyExists( derivatives, arguments.derivative ) ) {
			if ( !StructKeyExists( derivatives[ arguments.derivative ], "signature" ) ) {
				var sigSource = {
					  permissions     = derivatives[ arguments.derivative ].permissions     ?: "inherit"
					, transformations = derivatives[ arguments.derivative ].transformations ?: []
				};

				derivatives[ arguments.derivative ].signature = LCase( Hash( SerializeJson( sigSource ) ) );
			}

			return derivatives[ arguments.derivative ].signature;
		}

		return "";
	}

	public string function getDerivativeConfig( required string assetId ) {
		var config = [];
		var asset  = getAsset( id=arguments.assetId, selectFields=[ "focal_point", "crop_hint" ] );

		if ( len( asset.focal_point ) ) {
			config.append( "focal_point=#asset.focal_point#" );
		}
		if ( len( asset.crop_hint ) ) {
			config.append( "crop_hint=#asset.crop_hint#" );
		}

		return config.toList( "&" );
	}

	public string function getDerivativeConfigHash( required string config ) {
		if ( !len( arguments.config ) ) {
			return "";
		}

		return lcase( left( hash( arguments.config ), 12 ) );
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
				  "asset_version.id"
				, "asset_version.storage_path"
				, "asset_version.size"
				, "asset_version.asset_type"
				, "asset_version.raw_text_content"
				, "asset_version.focal_point"
				, "asset_version.crop_hint"
				, "asset_version.created_by"
				, "asset_version.updated_by"
				, "asset.title"
				, "asset.asset_folder"
				, "asset.is_trashed"
			]
		);

		if ( versionToMakeActive.recordCount ) {
			var versionImageDimension = _getImageInfo( getAssetBinary( arguments.assetId, arguments.versionId ) );
			var generatedAssetUrl     = generateAssetUrl(
				  id          = arguments.assetId
				, versionId   = arguments.versionId
				, storagePath = versionToMakeActive.storage_path
				, folder      = versionToMakeActive.asset_folder
				, trashed 	  = IsBoolean( versionToMakeActive.is_trashed ) && versionToMakeActive.is_trashed
			);
			var result = _getAssetDao().updateData( id=arguments.assetId, data={
				  active_version   = arguments.versionId
				, storage_path     = versionToMakeActive.storage_path
				, size             = versionToMakeActive.size
				, asset_type       = versionToMakeActive.asset_type
				, raw_text_content = versionToMakeActive.raw_text_content
				, focal_point      = versionToMakeActive.focal_point
				, crop_hint        = versionToMakeActive.crop_hint
				, created_by       = versionToMakeActive.created_by
				, updated_by       = versionToMakeActive.updated_by
				, width            = versionImageDimension.width  ?: ""
				, height           = versionImageDimension.height ?: ""
				, asset_url 	   = generatedAssetUrl
			} );

			invalidateRenderedAssetCache( arguments.assetId );
			for( var a in versionToMakeActive ) { var auditDetail = a; }
			$audit(
				  action   = "change_asset_version"
				, type     = "assetmanager"
				, detail   = auditDetail
				, recordId = auditDetail.id
			);

			return result;
		}

		return false;
	}

	public boolean function deleteAssetVersion( required string assetId, required string versionId ) {
		var asset = getAsset( id=arguments.assetId, selectFields=[ "id", "title", "active_version", "asset_folder" ] );

		if ( !asset.recordCount || asset.active_version == arguments.versionId ) {
			return false;
		}

		_deleteAssociatedFiles( arguments.assetId, asset.asset_folder, arguments.versionId );

		var result = _getAssetVersionDao().deleteData(
			filter = { id=arguments.versionId, asset=arguments.assetId }
		);

		for( var a in asset ) { var auditDetail = a; }
		auditDetail.append( arguments );
		$audit(
			  action   = "delete_asset_version"
			, type     = "assetmanager"
			, detail   = auditDetail
			, recordId = auditDetail.id
		);

		return result;
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

	public boolean function ensureAssetsAreInCorrectLocation(
		  string folderId = ""
		, string assetId  = ""
		, array  assetIds = []
	) {
		if ( Len( Trim( arguments.assetId ) ) ) {
			assets = getAsset( arguments.assetId );
		} else if ( Len( Trim( arguments.folderId ) ) ) {
			assets = getAllAssetsBeneathFolder( arguments.folderId );
		} else if ( arguments.assetIds.len() ) {
			assets = _getAssetDao().selectData( filter={ id=arguments.assetIds } );
		} else {
			assets = getAllAssetsBeneathFolder( getRootFolderId() );
		}

		if ( !assets.recordCount ) {
			return true;
		}

		for( var asset in assets ) {
			ensureAssetIsInCorrectLocation(
				  assetId     = asset.id
				, folderId    = asset.asset_folder
				, storagePath = asset.storage_path
			);
		}

		return true;
	}

	public void function ensureAssetIsInCorrectLocation(
		  required string assetId
		, required string folderId
		, required string storagePath
	) {
		var storageProvider = getStorageProviderForFolder( arguments.folderId );
		var isPrivate       = isAssetAccessRestricted( arguments.assetId );
		var derivatives     = _getDerivativeDao().selectData( filter={ asset=arguments.assetId }, selectFields=[ "id", "storage_path" ] );
		var versions        = _getAssetVersionDao().selectData( filter={ asset=arguments.assetId }, selectFields=[ "id", "storage_path" ] );
		var moveToCorrect   = function( required string storagePath ) {
			if ( !storageProvider.objectExists( path=arguments.storagePath, private=isPrivate ) ) {
				if ( storageProvider.objectExists( path=arguments.storagePath, private=!isPrivate ) ) {
					storageProvider.moveObject(
						  originalPath      = arguments.storagePath
						, newPath           = arguments.storagePath
						, originalIsPrivate = !isPrivate
						, newIsPrivate      = isPrivate
					);
					return true;
				}
			}
			return false;
		}

		if ( moveToCorrect( arguments.storagePath ) ) {
			_getAssetDao().updateData( id=arguments.assetId, data={ asset_url="" } );
		}
		for( var derivative in derivatives ) {
			if ( moveToCorrect( derivative.storage_path ) ) {
				_getDerivativeDao().updateData( id=derivative.id, data={ asset_url="" } );
			}
		}
		for( var version in versions ) {
			if ( moveToCorrect( version.storage_path ) ) {
				_getAssetVersionDao().updateData( id=version.id, data={ asset_url="" } );
			}
		}
	}

	public query function getAllAssetsBeneathFolder( required string folderId, boolean recursive=true ) {
		var folders = [ arguments.folderId ];

		if ( arguments.recursive ) {
			folders.append( getChildFolders( arguments.folderId ), true );
		}

		return _getAssetDao().selectData(
			filter = { asset_folder=folders }
		);
	}

	public array function getChildFolders( required string parent ) {
		var childFolders = [];
		var childRecords = _getFolderDao().selectData( filter={ parent_folder=arguments.parent }, selectFields=[ "id" ] );

		if ( childRecords.recordCount ) {
			childFolders = ValueArray( childRecords.id );
			for( var folder in childRecords ) {
				childFolders.append( getChildFolders( childRecords.id ), true );
			}
		}

		return childFolders;
	}

	public void function invalidateRenderedAssetCache( required string assetId ) {
		_getRenderedAssetCache().clearByKeySnippet(
			  keySnippet = "^asset-#arguments.assetId#"
			, regex      = true
		);
		$announceInterception( "onInvalidateRenderedAssetCache", arguments );
	}

	public any function getStorageProviderForFolder( required string folderId ) {
		var location = _getStorageLocationForFolder( arguments.folderId );

		if ( location.isEmpty() ) {
			return _getDefaultStorageProvider();
		}

		return _getStorageProviderService().getProvider(
			  id            = location.storageProvider
			, configuration = location.configuration
		);
	}

	public boolean function assetIsTooLargeForDerivatives( required string width, required string height ) {
		if ( !IsNumeric( arguments.width ) || !IsNumeric( arguments.height ) ) {
			return false;
		}

		var limits = _getDerivativeLimits();

		if ( limits.maxWidth && arguments.width > limits.maxWidth ) {
			return true;
		}
		if ( limits.maxHeight && arguments.height > limits.maxHeight ) {
			return true;
		}
		if ( limits.maxResolution && (arguments.width*arguments.height) > limits.maxResolution ) {
			return true;
		}

		return false;
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

	private array function _getPreconfiguredDerivativeTransformations( required string derivativeName ) {
		var configured = _getConfiguredDerivatives();

		if ( StructKeyExists( configured, arguments.derivativeName ) ) {
			return configured[ arguments.derivativeName ].transformations ?: [];
		}

		var adHocTransformation = _getAdhocDerivativeTransformationFromName( arguments.derivativeName );
		if ( adHocTransformation.len() ) {
			return adHocTransformation;
		}

		throw(
			  type    = "AssetManagerService.missingDerivativeConfiguration"
			, message = "No configured asset transformations were found for an asset derivative with name, [#arguments.derivativeName#]"
		);
	}

	private array function _getAdhocDerivativeTransformationFromName( required string derivativeName ) {
		if ( arguments.derivativeName.refind( "^([0-9]+)x([0-9]+)-([a-zA-Z]+)$" ) ) {
			var derivativeArgs = arguments.derivativeName.listToArray( "x-" );
			var transformArgs = {
				  width   = derivativeArgs[ 1 ]
				, height  = derivativeArgs[ 2 ]
				, quality = derivativeArgs[ 3 ]
				, maintainAspectRatio = true
			};
			return [ { method="resize", args=transformArgs } ];
		}

		return [];
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
				, value         = isSimpleValue( arguments.metaData[ key ] ) ? arguments.metaData[ key ] : serializeJson( arguments.metaData[ key ] )
			} );
		}
	}

	private boolean function _autoExtractDocumentMeta() {
		var setting = $getPresideSetting( "asset-manager", "retrieve_metadata" );

		return IsBoolean( setting ) && setting;
	}

	private struct function _getExcludeHiddenFilter() {
		return { filter="hidden is null or hidden = '0'" }
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
			, "focal_point"
			, "crop_hint"
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
				, focal_point      = asset.focal_point
				, crop_hint        = asset.crop_hint
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

	private void function _deleteAssociatedFiles( required string assetId, required string folderId, string versionId="", boolean softDelete=false, boolean private=false ) {
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
		var storageProvider = getStorageProviderForFolder( arguments.folderId );

		for( var version in versions ) {
			if ( arguments.softDelete ) {
				trashedPath = storageProvider.softDeleteObject( path=version.storage_path, private=arguments.private );
				assetVersionDao.updateData( id=version.id, data={ is_trashed=true, trashed_path=trashedPath, asset_url="" } );
			} else {
				storageProvider.deleteObject( version.storage_path );
			}
		}
		for( var derivative in derivatives ) {
			if ( arguments.softDelete ) {
				trashedPath = storageProvider.softDeleteObject( path=derivative.storage_path, private=arguments.private );
				derivativeDao.updateData( id=derivative.id, data={ is_trashed=true, trashed_path=trashedPath, asset_url="" } );
			} else {
				storageProvider.deleteObject( derivative.storage_path );
			}
		}
	}

	private void function _restoreAssociatedFiles( required string assetId, required any storageProvider, required boolean private ) {
		var assetVersionDao  = _getAssetVersionDao();
		var derivativeDao    = _getDerivativeDao();
		var versions         = assetVersionDao.selectData( filter={ asset=arguments.assetId, is_trashed=true }   , selectfields=[ "id", "storage_path", "trashed_path" ] );
		var derivatives      = derivativeDao.selectData( filter={ asset=arguments.assetId, is_trashed=true }, selectfields=[ "id", "storage_path", "trashed_path" ] );

		for( var version in versions ) {
			storageProvider.restoreObject( trashedPath=version.trashed_path, newPath=version.storage_path, private=arguments.private );
			assetVersionDao.updateData( id=version.id, data={ is_trashed=false, trashed_path="", asset_url="" } );
		}
		for( var derivative in derivatives ) {
			storageProvider.restoreObject( trashedPath=derivative.trashed_path, newPath=derivative.storage_path, private=arguments.private );
			derivativeDao.updateData( id=derivative.id, data={ is_trashed=false, trashed_path="", asset_url="" } );
		}
	}

	private string function _ensureUniqueTitle( required string title, required string folder, string existingId="" ) {
		var filter        = "title = :title and asset_folder = :asset_folder";
		var params        = { title=title, asset_folder=arguments.folder };
		var assetDao      = _getAssetDao();
		var maxLength     = Val( $getPresideObjectService().getObjectPropertyAttribute( "asset", "title", "maxLength", 150 ) );
		var originalTitle = arguments.title;
		var counter       = 0;

		if ( Len( Trim( arguments.existingId ) ) ) {
			filter &= " and id != :id";
			params.id = arguments.existingId;
		}

		while( assetDao.dataExists( filter=filter, filterParams=params ) ) {
			params.title = originalTitle & " " & ++counter;

			if ( Len( params.title ) > maxLength ) {
				params.title = Left( originalTitle, maxLength-Len( counter )-1 ) & " " & counter;
			}
		}

		return params.title;
	}

	private array function _userNoPermissionAssetFolders(){
		var noPermissionFolders    = [];
		var restrictedAssetFolders = $getPresideObject( "security_context_permission" ).selectData(
			  filter       = { context="assetmanagerfolder" }
			, selectFields = [ "context_key as folderId" ]
			, distinct     = true
		);

		for( var folder in restrictedAssetFolders ){
			if( !$getAdminPermissionService().hasPermission( permissionKey="assetmanager.general.navigate", context="assetmanagerfolder", contextKeys=[ restrictedAssetFolders.folderId ] ) ){
				arrayAppend( noPermissionFolders, restrictedAssetFolders.folderId );
			}
		}

		return noPermissionFolders;
	}


	private boolean function _isPendingAssetURL(  string asset_url="", asset_type="", storage_path=""  ) {
		return refindNoCase( 'pending-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{16}', arguments.asset_url ) || asset_type == "PENDING" || refindNoCase( 'pending-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{16}', arguments.storage_path );
	}

	private string function _slugifyTitleForFileName( required string title ) {
		var titleWithoutExtension = arguments.title.reReplace( "\.[a-z0-9]+$", "" );
		return $slugify( str=titleWithoutExtension, preserveCase=true );
	}

	private void function _autoQueueDerivatives(
		  required string assetId
		, required string type
		, required string typeGroup
		,          string versionId  = ""
		,          string configHash = ""
	) {
		if ( $isFeatureEnabled( "assetQueue" ) ) {
			var derivatives = _getConfiguredDerivatives();
			for( var derivativeName in derivatives ) {
				var autoQueueTypes = derivatives[ derivativeName ].autoQueue ?: [];

				if ( ArrayFindNoCase( autoQueueTypes, arguments.type ) || ArrayFindNoCase( autoQueueTypes, arguments.typeGroup ) ) {
					_getAssetQueueService().queueAssetGeneration(
						  assetId        = arguments.assetId
						, derivativeName = derivativeName
						, versionId      = arguments.versionId
						, configHash     = arguments.configHash
					);

				}
			}
		}
	}

	private binary function _getLargeImagePlaceholder() {
		return FileReadBinary( ExpandPath( _getDerivativeLimits().tooBigPlaceholder ) );
	}

// GETTERS AND SETTERS
	private any function _getDefaultStorageProvider() {
		return _defaultStorageProvider;
	}
	private void function _setDefaultStorageProvider( required any defaultStorageProvider ) {
		_defaultStorageProvider = arguments.defaultStorageProvider;
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

	private any function _getAssetDao() {
		return $getPresideObject( "asset" );
	}

	private any function _getAssetVersionDao() {
		return $getPresideObject( "asset_version" );
	}

	private any function _getFolderDao() {
		return $getPresideObject( "asset_folder" );
	}

	private any function _getDerivativeDao() {
		return $getPresideObject( "asset_derivative" );
	}

	private any function _getAssetMetaDao() {
		return $getPresideObject( "asset_meta" );
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

	private any function _getRenderedAssetCache() {
	    return _renderedAssetCache;
	}
	private void function _setRenderedAssetCache( required any renderedAssetCache ) {
	    _renderedAssetCache = arguments.renderedAssetCache;
	}

	private any function _getAssetQueueService() {
	    return _assetQueueService;
	}
	private void function _setAssetQueueService( required any assetQueueService ) {
	    _assetQueueService = arguments.assetQueueService;
	}

	private any function _getDerivativeGeneratorService() {
	    return _derivativeGeneratorService;
	}
	private void function _setDerivativeGeneratorService( required any derivativeGeneratorService ) {
	    _derivativeGeneratorService = arguments.derivativeGeneratorService;
	}

	private struct function _getDerivativeLimits() {
	    return _derivativeLimits;
	}
	private void function _setDerivativeLimits( required struct derivativeLimits ) {
		_derivativeLimits = {
			  maxHeight         = Val( arguments.derivativeLimits.maxHeight     ?: "" )
			, maxWidth          = Val( arguments.derivativeLimits.maxWidth      ?: "" )
			, maxResolution     = Val( arguments.derivativeLimits.maxResolution ?: "" )
			, tooBigPlaceholder = arguments.derivativeLimits.tooBigPlaceholder ?: "/preside/system/assets/images/placeholders/largeimage.jpg"
		};
	}
}
