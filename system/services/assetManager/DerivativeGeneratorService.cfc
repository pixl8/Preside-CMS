/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @assetManagerService.inject delayedInjector:assetManagerService
	 *
	 */
	public any function init( required any assetManagerService ) {
		_setAssetManagerService( arguments.assetManagerService );

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
		var assetBinary         = assetManagerService.getAssetBinary(
			  id                    = arguments.assetId
			, versionId             = arguments.versionId
			, throwOnMissing        = true
			, placeholderIfTooLarge = true
		);
		var fileProperties      = {
			  filename    = ListLast( asset.storage_path, "\/" )
			, fileExt     = ListLast( asset.storage_path, "." )
			, storagePath = arguments.storagePath
		};
		var lastFileExtension = fileProperties.fileExt;

		if( fileProperties.fileext == 'pdf' ){
			var pdfAttributes = {
				  action      = "getinfo"
				, source      = assetBinary
				, name        = 'result'
			};
			try{
				pdf attributeCollection=pdfAttributes;
			} catch( e ) {
				if( e.detail == 'Bad user Password' ){
					throw( type = "AssetManager.Password error" );
				}
			}
		}

		for( var transformation in transformations ) {
			var transformationArgs = transformation.args ?: {};
			transformationArgs.focalPoint = asset.focal_point;
			transformationArgs.cropHint   = asset.crop_hint;

			if ( not Len( Trim( transformation.inputFileType ?: "" ) ) or transformation.inputFileType eq fileProperties.fileext ) {
				assetBinary = _applyAssetTransformation(
					  assetBinary          = assetBinary
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

		assetManagerService.getStorageProviderForFolder( asset.asset_folder ).putObject(
			  object  = assetBinary
			, path    = fileProperties.storagePath
			, private = !assetManagerService.isDerivativePubliclyAccessible( arguments.derivativeName ) && assetManagerService.isAssetAccessRestricted( arguments.assetId )
		);

		if ( Len( Trim( arguments.derivativeId ) ) ) {
			$getPresideObject( "asset_derivative" ).updateData( id=arguments.derivativeId, data={
				  asset_type    = assetType.typeName
				, storage_path  = fileProperties.storagePath
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
				, config        = config
				, config_hash   = configHash
			} );
		}
	}

// PRIVATE HELPERS
	private binary function _applyAssetTransformation(
		  required binary assetBinary
		, required string transformationMethod
		, required struct transformationArgs
		, required struct fileProperties
	) {
		var args = Duplicate( arguments.transformationArgs );
		var coldboxHandler = "assettransformers.#arguments.transformationMethod#";

		args.asset          = arguments.assetBinary;
		args.fileProperties = arguments.fileProperties;

		return $runEvent( event=coldboxHandler, private=true, prePostExempt=true, eventArguments={ args=args } );
	}

// GETTERS AND SETTERS
	private any function _getAssetManagerService() {
	    return _assetManagerService.get();
	}
	private void function _setAssetManagerService( required any assetManagerService ) {
	    _assetManagerService = arguments.assetManagerService;
	}

}