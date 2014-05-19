component extends="preside.system.base.Service" output=false {

// CONSTRUCTOR
	public any function init( required any storageProvider, required any temporaryStorageProvider, required any assetTransformer, configuredDerivatives={}, struct configuredTypesByGroup={} ) output=false {
		super.init( argumentCollection = arguments );

		_discoverSystemFolderIds();

		_setStorageProvider( arguments.storageProvider );
		_setAssetTransformer( arguments.assetTransformer );
		_setTemporaryStorageProvider( arguments.temporaryStorageProvider );
		_setConfiguredDerivatives( arguments.configuredDerivatives );
		_setupConfiguredFileTypesAndGroups( arguments.configuredTypesByGroup );

		return this;
	}

// PUBLIC API METHODS
	public string function addFolder( required string label, string parent_folder="" ) output=false {
		if ( not Len( Trim( arguments.parent_folder ) ) ) {
			arguments.parent_folder = getRootFolderId();
		}
		return getPresideObject( "asset_folder" ).insertData( arguments );
	}

	public boolean function renameFolder( required string id, required string label ) output=false {
		return getPresideObject( "asset_folder" ).updateData(
			  id   = arguments.id
			, data = { label=arguments.label }
		);
	}

	public query function getFolder( required string id ) output=false {
		return getPresideObject( "asset_folder" ).selectData( filter="id = :id and parent_folder is not null", filterParams={ id = id } );
	}

	public query function getFolderAncestors( required string id ) output=false {
		var folder        = getFolder( id=arguments.id );
		var ancestors     = QueryNew( folder.columnList );
		var ancestorArray = [];

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

	public query function getAllFoldersForSelectList( string parentString="/ ", string parentFolder="", query finalQuery ) output=false {
		var folders = getPresideObject( "asset_folder" ).selectData(
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

	public array function expandTypeList( required array types ) output=false {
		var expanded = [];
		var types       = _getTypes();

		for( var typeName in arguments.types ){
			if ( types.keyExists( typeName ) ) {
				expanded.append( typeName );
			} else {
				for( var typeName in listTypesForGroup( typeName ) ){
					expanded.append( typeName );
				}
			}
		}

		return expanded;
	}

	public array function getAssetsForAjaxSelect( array ids=[], string searchQuery="", array allowedTypes=[], numeric maxRows=100 ) output=false {
		var assetDao    = getPresideObject( "asset" );
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
			filter &= " and ( asset.label like (:label) )";
			params.label = "%#arguments.searchQuery#%";
		}

		if ( params.isEmpty() ) {
			filter = {};
		}

		records = assetDao.selectData(
			  selectFields = [ "asset.id as value", "asset.label as text", "asset_folder.label as folder" ]
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

		records = getPresideObject( "asset" ).selectData(
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

		return getPresideObject( "asset_folder" ).updateData( id = arguments.id, data = {
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

	public struct function getTemporaryFileDetails( required string tmpId ) output=false {
		var details = {};
		var files   = _getTemporaryStorageProvider().listObjects( "/#arguments.tmpId#/" );

		for( var file in files ) {
			StructAppend( details, file );
		}

		details.label = details.name ?: "";

		return details;
	}

	public binary function getTemporaryFileBinary( required string tmpId ) output=false {
		var details = getTemporaryFileDetails( arguments.tmpId );

		return _getTemporaryStorageProvider().getObject( details.path ?: "" );
	}

	public string function saveTemporaryFileAsAsset( required string tmpId, string folder, struct assetData = {} ) {
		var fileDetails  = getTemporaryFileDetails( arguments.tmpId );
		var fileTypeInfo = getAssetType( filename=fileDetails.name, throwOnMissing=true );
		var newFileName  = "/uploaded/" & CreateUUId() & "." & fileTypeInfo.extension;
		var asset        = Duplicate( arguments.assetData );
		var newId        = "";

		if ( StructIsEmpty( fileDetails ) ) {
			return "";
		}

		_getStorageProvider().putObject(
			  object = _getTemporaryStorageProvider().getObject( fileDetails.path )
			, path   = newFileName
		);

		asset.asset_folder = arguments.folder;
		asset.asset_type   = fileTypeInfo.typeName;
		asset.storage_path = newFileName;
		StructAppend( asset, fileDetails, false );
		if ( not Len( Trim( asset.asset_folder ) ) ) {
			asset.asset_folder = getRootFolderId();
		}

		newId = getPresideObject( "asset" ).insertData( data=asset );
		deleteTemporaryFile( arguments.tmpId );

		return newId;
	}

	public boolean function editAsset( required string id, required struct data ) output=false {
		return getPresideObject( "asset" ).updateData( id=arguments.id, data=arguments.data );
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

	public query function getAsset( required string id, boolean throwOnMissing=false ) output=false {
		var asset = Len( Trim( arguments.id ) ) ? getPresideObject( "asset" ).selectData( id=arguments.id ) : QueryNew('');

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

	public boolean function trashAsset( required string id ) output=false {
		var assetDao    = getPresideObject( "asset" );
		var asset       = assetDao.selectData( id=arguments.id, selectFields=[ "storage_path", "label" ] );
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
			, label          = CreateUUId()
			, original_label = asset.label
			, asset_folder   = _getTrashFolderId()
		} );
	}

	public query function getAssetDerivative( required string assetId, required string derivativeName ) output=false {
		var derivativeDao = getPresideObject( "asset_derivative" );
		var derivative    = "";
		var selectFilter  = { "asset_derivative.asset" = arguments.assetId, "asset_derivative.label" = arguments.derivativeName };

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
		var derivativeDao = getPresideObject( "asset_derivative" );
		var selectFilter  = { "asset_derivative.asset" = arguments.assetId, "asset_derivative.label" = arguments.derivativeName };

		if ( !derivativeDao.dataExists( filter=selectFilter ) ) {
			return createAssetDerivative( argumentCollection = arguments );
		}
	}

	public string function createAssetDerivative(
		  required string assetId
		, required string derivativeName
		,          array  transformations = _getPreconfiguredDerivativeTransformations( arguments.derivativeName )
	) output=false {

		var asset           = getAsset( id=arguments.assetId, throwOnMissing=true );
		var assetBinary     = getAssetBinary( id=arguments.assetId, throwOnMissing=true );
		var filename        = ListLast( asset.storage_path, "/" );
		var fileext         = ListLast( filename, "." );
		var derivativeSlug  = ReReplace( arguments.derivativeName, "\W", "_", "all" );
		var storagePath     = "/derivatives/#derivativeSlug#/#derivativeSlug#_#filename#";

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

		return getPresideObject( "asset_derivative" ).insertData( {
			  asset_type   = assetType.typeName
			, asset        = arguments.assetId
			, label        = arguments.derivativeName
			, storage_path = storagePath
		} );
	}

// PRIVATE HELPERS
	private void function _discoverSystemFolderIds() output=false {
		var dao         = getPresideObject( "asset_folder" );
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
}