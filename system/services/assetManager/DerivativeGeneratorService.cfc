/**
 * @presideService true
 * @singleton      true
 * @feature        assetManager
 */
component {

// CONSTRUCTOR
	/**
	 * @assetManagerService.inject    delayedInjector:assetManagerService
	 * @storageProviderService.inject delayedInjector:storageProviderService
	 *
	 */
	public any function init( required any assetManagerService, required any storageProviderService ) {
		_setAssetManagerService( arguments.assetManagerService );
		_setStorageProviderService( arguments.storageProviderService );

		return this;
	}

// PUBLIC API METHODS
	public string function generate(
		  required string assetId
		, required string derivativeName
		, required string versionId
		, required array  transformations
		, required string derivativeId
		, required string derivativeSignature
		, required string assetTransformationConfig
		, required string assetTransformationConfigHash
		, required query  asset
		, required string storagePath
	) {
		var assetManagerService = _getAssetManagerService();
		var signature           = arguments.derivativeSignature;
		var config              = arguments.assetTransformationConfig;
		var configHash          = arguments.assetTransformationConfigHash;
		var tmpFile             = getTempFile( getTempDirectory(), "" );
		var assetBinaryOrPath   = assetManagerService.getAssetBinary(
			  id                     = arguments.assetId
			, versionId              = arguments.versionId
			, throwOnMissing         = true
			, placeholderIfTooLarge  = true
			, getFilePathIfSupported = true
		);
		var fileProperties      = {
			  filename    = ListLast( asset.storage_path, "\/" )
			, fileExt     = ListLast( asset.storage_path, "." )
			, storagePath = arguments.storagePath
		};
		var lastFileExtension = fileProperties.fileExt;

		if ( IsBinary( assetBinaryOrPath ) ) {
			FileWrite( tmpFile, assetBinaryOrPath );
		} else {
			FileCopy( assetBinaryOrPath, tmpFile );
		}

		if( fileProperties.fileext == 'pdf' ){
			var result = "";
			var pdfAttributes = {
				  action      = "getinfo"
				, source      = tmpFile
				, name        = 'result'
			};
			try {
				pdf attributeCollection=pdfAttributes;
			} catch( e ) {
				if( e.detail == 'Bad user Password' ){
					_fileDelete( tmpFile );
					throw( type = "AssetManager.Password error" );
				}
			}
		}

		try {
			for( var transformation in transformations ) {
				var transformationArgs = transformation.args ?: {};
				transformationArgs.focalPoint   = asset.focal_point;
				transformationArgs.cropHint     = asset.crop_hint;
				transformationArgs.resizeNoCrop = $helpers.isTrue( asset.resize_no_crop );

				if ( not Len( Trim( transformation.inputFileType ?: "" ) ) or transformation.inputFileType eq fileProperties.fileext ) {
					_applyAssetTransformation(
						  filePath             = tmpFile
						, transformationMethod = transformation.method ?: ""
						, transformationArgs   = transformationArgs
						, fileProperties       = fileProperties
					);

					if( lastFileExtension != fileProperties.fileExt ) {
						fileProperties.storagePath = ReReplaceNoCase( fileProperties.storagePath, "\.#lastFileExtension#$", ".#fileProperties.fileExt#" );
						fileProperties.fileName    = ReReplaceNoCase( fileProperties.fileName, "\.#lastFileExtension#$", ".#fileProperties.fileExt#" );

						lastFileExtension = fileProperties.fileExt;
					}
				}
			}

			var assetType = assetManagerService.getAssetType( filename=fileProperties.storagePath, throwOnMissing=true );
			var sp = assetManagerService.getStorageProviderForFolder( asset.asset_folder );
			if ( _getStorageProviderService().providerSupportsFileSystem( sp ) ) {
				sp.putObjectFromLocalPath(
					  localPath = tmpFile
					, path      = fileProperties.storagePath
					, private   = !assetManagerService.isDerivativePubliclyAccessible( arguments.derivativeName ) && assetManagerService.isAssetAccessRestricted( arguments.assetId )
				);
			} else {
				sp.putObject(
					  object  = FileReadBinary( tmpFile )
					, path    = fileProperties.storagePath
					, private = !assetManagerService.isDerivativePubliclyAccessible( arguments.derivativeName ) && assetManagerService.isAssetAccessRestricted( arguments.assetId )
				);
			}
		} catch( any e ) {
			rethrow;
		} finally {
			_fileDelete( tmpFile );
		}

		if ( Len( Trim( arguments.derivativeId ) ) ) {
			$getPresideObject( "asset_derivative" ).updateData( id=arguments.derivativeId, data={
				  asset_type    = assetType.typeName
				, storage_path  = fileProperties.storagePath
				, width         = fileProperties.width  ?: ""
				, height        = fileProperties.height ?: ""
				, config        = config
				, config_hash   = configHash
			} );

			return arguments.derivativeId;
		} else {
			return $getPresideObject( "asset_derivative" ).insertData( {
				  asset_type    = assetType.typeName
				, asset         = arguments.assetId
				, asset_version = arguments.versionId
				, label         = arguments.derivativeName & signature
				, storage_path  = fileProperties.storagePath
				, width         = fileProperties.width  ?: ""
				, height        = fileProperties.height ?: ""
				, config        = config
				, config_hash   = configHash
			} );
		}
	}

// PRIVATE HELPERS
	private void function _applyAssetTransformation(
		  required string filePath
		, required string transformationMethod
		, required struct transformationArgs
		, required struct fileProperties
	) {
		var args = Duplicate( arguments.transformationArgs );
		var coldboxHandler = "assettransformers.#arguments.transformationMethod#";

		args.asset          = arguments.filePath; // backward compat
		args.filePath       = arguments.filePath;
		args.fileProperties = arguments.fileProperties;

		return $runEvent( event=coldboxHandler, private=true, prePostExempt=true, eventArguments={ args=args } );
	}

	private void function _fileDelete( required string filePath ) {
		if ( FileExists( arguments.filePath ) ) {
			try {
				FileDelete( arguments.filePath );
			} catch( any e ) {
				if ( FileExists( arguments.filePath ) ) {
					rethrow;
				}
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getAssetManagerService() {
	    return _assetManagerService.get();
	}
	private void function _setAssetManagerService( required any assetManagerService ) {
	    _assetManagerService = arguments.assetManagerService;
	}

	private any function _getStorageProviderService() {
	    return _storageProviderService;
	}
	private void function _setStorageProviderService( required any storageProviderService ) {
	    _storageProviderService = arguments.storageProviderService;
	}

}