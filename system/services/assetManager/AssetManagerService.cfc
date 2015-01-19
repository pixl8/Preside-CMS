component singleton=true output=false {

// CONSTRUCTOR
	/**
	 * @storageProvider.inject            assetStorageProvider
	 * @temporaryStorageProvider.inject   tempStorageProvider
	 * @assetTransformer.inject           AssetTransformer
	 * @tikaWrapper.inject                TikaWrapper
	 * @systemConfigurationService.inject systemConfigurationService
	 * @configuredDerivatives.inject      coldbox:setting:assetManager.derivatives
	 * @configuredTypesByGroup.inject     coldbox:setting:assetManager.types
	 * @assetDao.inject                   presidecms:object:asset
	 * @folderDao.inject                  presidecms:object:asset_folder
	 * @derivativeDao.inject              presidecms:object:asset_derivative
	 * @assetMetaDao.inject               presidecms:object:asset_meta
	 */
	public any function init(
		  required any    storageProvider
		, required any    temporaryStorageProvider
		, required any    assetTransformer
		, required any    tikaWrapper
		, required any    systemConfigurationService
		, required any    assetDao
		, required any    folderDao
		, required any    derivativeDao
		, required any    assetMetaDao
		,          struct configuredDerivatives={}
		,          struct configuredTypesByGroup={}
	) output=false {
 		_setAssetDao( arguments.assetDao );
		_setFolderDao( arguments.folderDao );

		_discoverSystemFolderIds();

		_setStorageProvider( arguments.storageProvider );
		_setAssetTransformer( arguments.assetTransformer );
		_setTemporaryStorageProvider( arguments.temporaryStorageProvider );
		_setTikaWrapper( arguments.tikaWrapper );
		_setSystemConfigurationService( arguments.systemConfigurationService );

		_setConfiguredDerivatives( arguments.configuredDerivatives );
		_setupConfiguredFileTypesAndGroups( arguments.configuredTypesByGroup );
		_setDerivativeDao( arguments.derivativeDao );
		_setAssetMetaDao( arguments.assetMetaDao );

		return this;
	}

// PUBLIC API METHODS
	public string function addFolder( required string label, string parent_folder="" ) output=false {
		if ( not Len( Trim( arguments.parent_folder ) ) ) {
			arguments.parent_folder = getRootFolderId();
		}
		return _getFolderDao().insertData( arguments );
	}

	public boolean function editFolder( required string id, required struct data ) output=false {
		if ( arguments.data.keyExists( "parent_folder" ) && not Len( Trim( arguments.data.parent_folder ) ) ) {
			arguments.data.parent_folder = getRootFolderId();
		}

		return _getFolderDao().updateData(
			  id   = arguments.id
			, data = arguments.data
		);
	}

	public query function getFolder( required string id ) output=false {
		return _getFolderDao().selectData( filter="id = :id", filterParams={ id = id } );
	}

	public query function getFolderAncestors( required string id, boolean includeChildFolder=false ) output=false {
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

	public struct function getCascadingFolderSettings( required string id, required array settings ) output=false {
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

	public query function getAllFoldersForSelectList( string parentString="/ ", string parentFolder="", query finalQuery ) output=false {
		var folders = _getFolderDao().selectData(
			  selectFields = [ "id", "label" ]
			, filter       = { parent_folder = Len( Trim( arguments.parentFolder ) ) ? arguments.parentFolder : getRootFolderId() }
			, orderBy      = "label"
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
		var tree    = [];
		var folders = _getFolderDao().selectData(
			  selectFields = [ "id", "label", "access_restriction" ]
			, filter       = Len( Trim( arguments.parentFolder ) ) ? { parent_folder =  arguments.parentFolder } : { id = getRootFolderId() }
			, orderBy      = "label"
		);

		for ( var folder in folders ) {
			if ( folder.access_restriction == "inherit" ) {
				folder.access_restriction = arguments.parentRestriction;
			}
			folder.permissionContext = arguments.permissionContext;
			folder.permissionContext.prepend( folder.id );

			folder.append( { children=getFolderTree( folder.id, folder.access_restriction, folder.permissionContext ) } );

			tree.append( folder );
		}

		return tree;
	}

	public array function expandTypeList( required array types, boolean prefixExtensionsWithPeriod=false ) output=false {
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

	) output=false {

		var result       = { totalRecords = 0, records = "" };
		var parentFolder = Len( Trim( arguments.folder ) ) ? arguments.folder : getRootFolderId();
		var args         = {
			  startRow = arguments.startRow
			, maxRows  = arguments.maxRows
			, orderBy  = arguments.orderBy
		};

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.filter       = "asset_folder = :asset_folder and title like :q";
			args.filterParams = { asset_folder=parentFolder, q = { type="varchar", value="%" & arguments.searchQuery & "%" } };
		} else {
			args.filter = { asset_folder = parentFolder };
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

	public array function getAssetsForAjaxSelect( array ids=[], string searchQuery="", array allowedTypes=[], numeric maxRows=100 ) output=false {
		var assetDao    = _getAssetDao();
		var filter      = "( asset.asset_folder != :asset_folder )";
		var params      = { asset_folder = _getTrashFolderId() };
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
			filter &= " and ( asset.title like (:title) )";
			params.title = "%#arguments.searchQuery#%";
		}

		if ( params.isEmpty() ) {
			filter = {};
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

	public string function getPrefetchCachebusterForAjaxSelect( array allowedTypes=[] ) output=false {
		var filter  = "( asset.asset_folder != :asset_folder )";
		var params  = { asset_folder = _getTrashFolderId() };
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

	public boolean function trashFolder( required string id ) output=false {
		var folder = getFolder( arguments.id );

		if ( !folder.recordCount ) {
			return false;
		}

		return _getFolderDao().updateData( id = arguments.id, data = {
			  parent_folder  = _getTrashFolderId()
			, label          = CreateUUId()
			, original_label = folder.label
		} );
	}

	public string function uploadTemporaryFile( required string fileField ) output=false {
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

	public void function deleteTemporaryFile( required string tmpId ) output=false {
		var details = getTemporaryFileDetails( arguments.tmpId );
		if ( Len( Trim( details.path ?: "" ) ) ) {
			_getTemporaryStorageProvider().deleteObject( details.path );
		}
	}

	public struct function getTemporaryFileDetails( required string tmpId, boolean includeMeta=false ) output=false {
		var storageProvider = _getTemporaryStorageProvider();
		var files           = storageProvider.listObjects( "/#arguments.tmpId#/" );
		var details         = {};

		for( var file in files ) {
			if ( arguments.includeMeta ) {
				details = _getTikaWrapper().getMetadata( storageProvider.getObject( file.path ) );
			}

			StructAppend( details, file );

			details.title = details.title ?: ( details.name ?: "" );

			break;
		}

		return details;
	}

	public binary function getTemporaryFileBinary( required string tmpId ) output=false {
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

	public string function addAsset( required binary fileBinary, required string fileName, required string folder, struct assetData={} ) output=false {
		var fileTypeInfo = getAssetType( filename=arguments.fileName, throwOnMissing=true );
		var newFileName  = "/uploaded/" & CreateUUId() & "." & fileTypeInfo.extension;
		var asset        = Duplicate( arguments.assetData );

		_getStorageProvider().putObject(
			  object = arguments.fileBinary
			, path   = newFileName
		);

		asset.asset_folder     = arguments.folder;
		asset.asset_type       = fileTypeInfo.typeName;
		asset.storage_path     = newFileName;

		if ( _autoExtractDocumentMeta() ) {
			asset.raw_text_content = _getTikaWrapper().getText( arguments.fileBinary );
		}

		if ( not Len( Trim( asset.asset_folder ) ) ) {
			asset.asset_folder = getRootFolderId();
		}

		var newId = _getAssetDao().insertData( data=asset );

		if ( _autoExtractDocumentMeta() ) {
			_saveAssetMetaData( assetId=newId, metaData=_getTikaWrapper().getMetaData( arguments.fileBinary ) );
		}

		return newId;
	}

	public string function getRawTextContent( required string assetId ) output=false {
		var asset = getAsset( id=arguments.assetId, selectFields=[ "asset_type", "raw_text_content" ] );

		if ( asset.recordCount && asset.asset_type != "image" ) {
			if ( Len( Trim( asset.raw_text_content ) ) ) {
				return asset.raw_text_content;
			}
		}

		if ( _autoExtractDocumentMeta() ) {
			var fileBinary = getAssetBinary( arguments.assetId );
			if ( !IsNull( fileBinary ) ) {
				var rawText = _getTikaWrapper().getText( fileBinary );
				if ( Len( Trim( rawText ) ) ) {
					_getAssetDao().updateData( id=arguments.assetId, data={ raw_text_content=rawText } );
				}

				return rawText;
			}
		}

		return "";
	}

	public boolean function editAsset( required string id, required struct data ) output=false {
		return _getAssetDao().updateData( id=arguments.id, data=arguments.data );
	}

	public struct function getAssetType( string filename="", string name=ListLast( arguments.fileName, "." ), boolean throwOnMissing=false ) output=false {
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

	public array function listTypesForGroup( required string groupName ) output=false {
		var groups = _getGroups();

		return groups[ arguments.groupName ] ?: [];
	}

	public query function getAsset( required string id, array selectFields=[], boolean throwOnMissing=false ) output=false {
		var asset = Len( Trim( arguments.id ) ) ? _getAssetDao().selectData( id=arguments.id, selectFields=arguments.selectFields ) : QueryNew('');

		if ( asset.recordCount or not throwOnMissing ) {
			return asset;
		}

		throw(
			  type    = "AssetManager.assetNotFound"
			, message = "Asset with id [#arguments.id#] not found"
		);
	}

	public binary function getAssetBinary( required string id, boolean throwOnMissing=false ) output=false {
		var asset = getAsset( id = arguments.id, throwOnMissing = arguments.throwOnMissing );
		var assetBinary = "";

		if ( asset.recordCount ) {
			return _getStorageProvider().getObject( asset.storage_path );
		}
	}

	public string function getAssetEtag( required string id, string derivativeName="", boolean throwOnMissing=false ) output="false" {
		var asset = "";

		if ( Len( Trim( arguments.derivativeName ) ) ) {
			asset = getAssetDerivative(
				  assetId        = arguments.id
				, derivativeName = arguments.derivativeName
				, throwOnMissing = arguments.throwOnMissing
			);
		} else {
			asset = getAsset( id = arguments.id, throwOnMissing = arguments.throwOnMissing );
		}

		if ( asset.recordCount ) {
			var assetInfo = _getStorageProvider().getObjectInfo( asset.storage_path );
			var etag      = LCase( Hash( SerializeJson( assetInfo ) ) )

			return Left( etag, 8 );
		}

		return "";
	}

	public boolean function trashAsset( required string id ) output=false {
		var assetDao    = _getAssetDao();
		var asset       = assetDao.selectData( id=arguments.id, selectFields=[ "storage_path", "title" ] );
		var trashedPath = "";

		if ( !asset.recordCount ) {
			return false;
		}

		trashedPath = _getStorageProvider().softDeleteObject( asset.storage_path );
		if ( !Len( Trim( trashedPath ) ) ) {
			return false;
		}

		return assetDao.updateData( id=arguments.id, data={
			  trashed_path   = trashedPath
			, title          = CreateUUId()
			, original_title = asset.title
			, asset_folder   = _getTrashFolderId()
		} );
	}

	public query function getAssetDerivative( required string assetId, required string derivativeName ) output=false {
		var derivativeDao = _getDerivativeDao();
		var derivative    = "";
		var signature     = getDerivativeConfigSignature( arguments.derivativeName );
		var selectFilter  = { "asset_derivative.asset" = arguments.assetId, "asset_derivative.label" = arguments.derivativeName & signature };

		lock type="exclusive" name="getAssetDerivative( #assetId#, #arguments.derivativeName# )" timeout=5 {
			derivative = derivativeDao.selectData( filter=selectFilter );
			if ( derivative.recordCount ) {
				return derivative;
			}

			createAssetDerivative( assetId=arguments.assetId, derivativeName=arguments.derivativeName );

			return derivativeDao.selectData( filter=selectFilter );
		}
	}

	public binary function getAssetDerivativeBinary( required string assetId, required string derivativeName ) output=false {
		var derivative = getAssetDerivative( assetId = arguments.assetId, derivativeName = arguments.derivativeName );

		if ( derivative.recordCount ) {
			return _getStorageProvider().getObject( derivative.storage_path );
		}
	}

	public string function createAssetDerivativeWhenNotExists(
		  required string assetId
		, required string derivativeName
		,          array  transformations = _getPreconfiguredDerivativeTransformations( arguments.derivativeName )
	) output=false {
		var derivativeDao = _getDerivativeDao();
		var signature     = getDerivativeConfigSignature( arguments.derivativeName );
		var selectFilter  = { "asset_derivative.asset" = arguments.assetId, "asset_derivative.label" = arguments.derivativeName & signature };

		if ( !derivativeDao.dataExists( filter=selectFilter ) ) {
			return createAssetDerivative( argumentCollection = arguments );
		}
	}

	public string function createAssetDerivative(
		  required string assetId
		, required string derivativeName
		,          array  transformations = _getPreconfiguredDerivativeTransformations( arguments.derivativeName )
	) output=false {
		var signature       = getDerivativeConfigSignature( arguments.derivativeName );
		var asset           = getAsset( id=arguments.assetId, throwOnMissing=true );
		var assetBinary     = getAssetBinary( id=arguments.assetId, throwOnMissing=true );
		var filename        = LCase( Hash( signature & ListLast( asset.storage_path, "/" ) ) );
		var fileext         = ListLast( filename, "." );
		var derivativeSlug  = ReReplace( arguments.derivativeName, "\W", "_", "all" );
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

		_getStorageProvider().putObject( assetBinary, storagePath );

		return _getDerivativeDao().insertData( {
			  asset_type   = assetType.typeName
			, asset        = arguments.assetId
			, label        = arguments.derivativeName & signature
			, storage_path = storagePath
		} );
	}

	public struct function getAssetPermissioningSettings( required string assetId ) output=false {
		var asset    = getAsset( arguments.assetId );
		var settings = {
			  contextTree       = [ arguments.assetId ] //ListToArray( ValueList( folders.id ) ) };
			, restricted        = false
			, fullLoginRequired = false
		}

		if ( !asset.recordCount ){ return settings; }

		var folders = getFolderAncestors( asset.asset_folder, true );

		for( var folder in folders ){ settings.contextTree.append( folder.id ); }

		if ( asset.access_restriction != "inherit" ) {
			settings.restricted        = asset.access_restriction == "full";
			settings.fullLoginRequired = IsBoolean( asset.full_login_required ) && asset.full_login_required;

			return settings;
		}

		for( var folder in folders ) {
			if ( folder.access_restriction != "inherit" ) {
				settings.restricted        = folder.access_restriction == "full";
				settings.fullLoginRequired = IsBoolean( folder.full_login_required ) && folder.full_login_required;

				return settings;
			}
		}

		return settings;
	}

	public boolean function isDerivativePubliclyAccessible( required string derivative ) output=false {
		var derivatives = _getConfiguredDerivatives();

		return ( derivatives[ arguments.derivative ].permissions ?: "inherit" ) == "public";
	}

	public string function getDerivativeConfigSignature( required string derivative ) output=false {
		var derivatives = _getConfiguredDerivatives();

		if ( derivatives.keyExists( arguments.derivative ) ) {
			if ( !derivatives[ arguments.derivative ].keyExists( "signature" ) ) {
				derivatives[ arguments.derivative ].signature = LCase( Hash( SerializeJson( derivatives[ arguments.derivative ] ) ) );
			}

			return derivatives[ arguments.derivative ].signature;
		}

		return "";
	}

// PRIVATE HELPERS
	private void function _discoverSystemFolderIds() output=false {
		var dao         = _getFolderDao();
		var rootFolder  = dao.selectData( selectFields=[ "id" ], filter="parent_folder is null and label = :label", filterParams={ label="$root" } );
		var trashFolder = dao.selectData( selectFields=[ "id" ], filter="parent_folder is null and label = :label", filterParams={ label="$recycle_bin" } );

		if ( rootFolder.recordCount ) {
			_setRootFolderId( rootFolder.id );
		} else {
			_setRootFolderId( dao.insertData( data={ label="$root" } ) );
		}

		if ( trashFolder.recordCount ) {
			_setTrashFolderId( trashFolder.id );
		} else {
			_setTrashFolderId( dao.insertData( data={ label="$recycle_bin" } ) );
		}

	}

	private binary function _applyAssetTransformation( required binary assetBinary, required string transformationMethod, required struct transformationArgs ) output=false {
		var args        = Duplicate( arguments.transformationArgs );

		// todo, sanity check the input

		args.asset = arguments.assetBinary;
		return _getAssetTransformer()[ arguments.transformationMethod ]( argumentCollection = args );
	}

	private array function _getPreconfiguredDerivativeTransformations( required string derivativeName ) output=false {
		var configured = _getConfiguredDerivatives();

		if ( StructKeyExists( configured, arguments.derivativeName ) ) {
			return configured[ arguments.derivativeName ].transformations ?: [];
		}

		throw(
			  type    = "AssetManagerService.missingDerivativeConfiguration"
			, message = "No configured asset transformations were found for an asset derivative with name, [#arguments.derivativeName#]"
		);
	}

	private void function _setupConfiguredFileTypesAndGroups( required struct typesByGroup ) output=false {
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

	private void function _saveAssetMetaData( required string assetId, required struct metaData ) output=false {
		var dao = _getAssetMetaDao();

		dao.deleteData( filter={ asset=assetId } );
		for( var key in arguments.metaData ) {
			dao.insertData( {
				  asset = arguments.assetId
				, key   = key
				, value = arguments.metaData[ key ]
			} );
		}
	}

	private boolean function _autoExtractDocumentMeta() output=false {
		var setting = _getSystemConfigurationService().getSetting( "asset-manager", "retrieve_metadata" );

		return IsBoolean( setting ) && setting;
	}

// GETTERS AND SETTERS
	private any function _getStorageProvider() output=false {
		return _storageProvider;
	}
	private void function _setStorageProvider( required any storageProvider ) output=false {
		_storageProvider = arguments.storageProvider;
	}

	private any function _getTemporaryStorageProvider() output=false {
		return _temporaryStorageProvider;
	}
	private void function _setTemporaryStorageProvider( required any temporaryStorageProvider ) output=false {
		_temporaryStorageProvider = arguments.temporaryStorageProvider;
	}

	private any function _getAssetTransformer() output=false {
		return _assetTransformer;
	}
	private void function _setAssetTransformer( required any assetTransformer ) output=false {
		_assetTransformer = arguments.assetTransformer;
	}

	private struct function _getConfiguredDerivatives() output=false {
		return _configuredDerivatives;
	}
	private void function _setConfiguredDerivatives( required struct configuredDerivatives ) output=false {
		_configuredDerivatives = arguments.configuredDerivatives;
	}

	public string function getRootFolderId() output=false {
		return _rootFolderId;
	}
	private void function _setRootFolderId( required string rootFolderId ) output=false {
		_rootFolderId = arguments.rootFolderId;
	}

	private string function _getTrashFolderId() output=false {
		return _trashFolderId;
	}
	private void function _setTrashFolderId( required string trashFolderId ) output=false {
		_trashFolderId = arguments.trashFolderId;
	}

	private any function _getGroups() output=false {
		return _groups;
	}
	private void function _setGroups( required any groups ) output=false {
		_groups = arguments.groups;
	}

	private struct function _getTypes() output=false {
		return _types;
	}
	private void function _setTypes( required struct types ) output=false {
		_types = arguments.types;
	}

	private any function _getSystemConfigurationService() output=false {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) output=false {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getAssetDao() output=false {
		return _assetDao;
	}
	private void function _setAssetDao( required any assetDao ) output=false {
		_assetDao = arguments.assetDao;
	}

	private any function _getFolderDao() output=false {
		return _folderDao;
	}
	private void function _setFolderDao( required any folderDao ) output=false {
		_folderDao = arguments.folderDao;
	}

	private any function _getDerivativeDao() output=false {
		return _derivativeDao;
	}
	private void function _setDerivativeDao( required any derivativeDao ) output=false {
		_derivativeDao = arguments.derivativeDao;
	}

	private any function _getAssetMetaDao() output=false {
		return _assetMetaDao;
	}
	private void function _setAssetMetaDao( required any assetMetaDao ) output=false {
		_assetMetaDao = arguments.assetMetaDao;
	}

	private any function _getTikaWrapper() output=false {
		return _tikaWrapper;
	}
	private void function _setTikaWrapper( required any tikaWrapper ) output=false {
		_tikaWrapper = arguments.tikaWrapper;
	}
}