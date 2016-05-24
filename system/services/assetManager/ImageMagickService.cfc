/**
 * Provides image manipulation logic using ImageMagick
 *
 * @autodoc
 * @singleton
 * @presideservice
 *
 */
component displayname="ImageMagick"  {

	public any function init() {
		_setActiveOperations( {} );
		_setActiveOperationsLockName( "imageMagickActiveOperationsLock_" & CreateUUId() );

		return this;
	}

	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
	) {
		var currentImageInfo = getImageInformation( arguments.asset );

		if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		}

		var currentImageInfo  = {};
		var tmpSourceFilePath = getTempFile( GetTempDirectory(), "mgk" );
		var tmpDestFilePath   = getTempFile( GetTempDirectory(), "mgk" );

		FileWrite( tmpSourceFilePath, arguments.asset );

		try {
			imageMagickResize(
				  sourceFile      = tmpSourceFilePath
				, destinationFile = tmpDestFilePath
				, qualityArgs     = _cfToImQuality( arguments.quality )
				, width           = arguments.width
				, height          = arguments.height
				, expand          = maintainAspectRatio
				, crop            = maintainAspectRatio
			);

			var binary = FileReadBinary( tmpDestFilePath );
		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			FileDelete( tmpSourceFilePath );
			FileDelete( tmpDestFilePath   );
		}

		return binary;
	}

	public binary function pdfPreview(
		  required binary asset
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
	) {
		var imagePrefix    = CreateUUId();
		var tmpFilePathPDF = GetTempFile( GetTempDirectory(), "mgk" );
		var tmpFilePathJpg = GetTempFile( GetTempDirectory(), "mgk" ) & ".jpg";
		var args           = '"#tmpFilePathPDF#[0]" -density 100 -colorspace sRGB "#tmpFilePathJpg#"';

		FileWrite( tmpFilePathPDF, arguments.asset );

		_exec( command="convert", args=args );

		var binary = FileReadBinary( tmpFilePathJpg );

		FileDelete( tmpFilePathPDF );
		FileDelete( tmpFilePathJpg );

		return binary;
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality = "highPerformance"
	) {
		var currentImageInfo = getImageInformation( arguments.asset );

		if ( currentImageInfo.width <= arguments.width && currentImageInfo.height <= arguments.height ) {
			return arguments.asset;
		}

		var tmpSourceFilePath = getTempFile( GetTempDirectory(), "mgk" );
		var tmpDestFilePath   = getTempFile( GetTempDirectory(), "mgk" );
		var shrinkToWidth     = arguments.width;
		var shrinkToHeight    = arguments.height;
		var widthChangeRatio  = currentImageInfo.width / shrinkToWidth;
		var heightChangeRatio = currentImageInfo.height / shrinkToHeight;

		FileWrite( tmpSourceFilePath, arguments.asset );

		if ( widthChangeRatio > heightChangeRatio ) {
			shrinkToHeight = 0;
		} else {
			shrinkToWidth = 0;
		}

		try {
			imageMagickResize(
				  sourceFile      = tmpSourceFilePath
				, destinationFile = tmpDestFilePath
				, qualityArgs      = _cfToImQuality( arguments.quality )
				, width           = shrinkToWidth
				, height          = shrinkToHeight
				, expand          = true
				, crop            = false
			);

			var binary = FileReadBinary( tmpDestFilePath );
		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			FileDelete( tmpSourceFilePath );
			FileDelete( tmpDestFilePath   );
		}

		return binary;
	}

	public string function imageMagickResize(
		  required string  sourceFile
		, required string  destinationFile
		, required string  qualityArgs
		, required numeric width
		, required numeric height
		,          boolean expand    = false
		,          boolean crop      = false
		,          string  gravity   = 'center'
	) {
		var defaultSettings = "-unsharp 0.25x0.25+24+0.065 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -colorspace sRGB -strip";
		var args            = '"#arguments.sourceFile#" #arguments.qualityArgs# #defaultSettings# -thumbnail #( arguments.width ? arguments.width : '' )#x#( arguments.height ? arguments.height : '' )#';
		var interlace       = $getPresideSetting( "asset-manager", "imagemagick_interlace" );

		if ( arguments.expand ) {
			if ( arguments.crop ) {
				args &= "^";
			}
			args &= " -gravity #arguments.gravity# -extent #arguments.width#x#arguments.height#";
		}

		interlace = ( IsBoolean( interlace ) && interlace ) ? "line" : "none";
		args &= " -interlace #interlace#";

		args &= " " & '"#arguments.destinationFile#"';

		_exec( command="convert", args=args );

		_checkResize( argumentCollection=arguments );

		return arguments.destinationFile;
	}

	public struct function getImageInformation( required binary asset ) {
		var tmpFilePath = GetTempFile( GetTempDirectory(), "mgk" );

		FileWrite( tmpFilePath, arguments.asset );

		var rawInfo = Trim( _exec( command="identify", args='-format "%wx%h" "#tmpFilePath#"' ) );

		FileDelete( tmpFilePath );

		if ( ReFindNoCase( "^[0-9]+x[0-9]+$", rawInfo ) ) {
			return {
				  width  = ListFirst( rawInfo, "x" )
				, height = ListLast( rawInfo, "x" )
			};
		}

		throw( type="AssetTransformer.shrinkToFit.notAnImage" );
	}

// PRIVATE HELPERS
	private string function _exec( required string command, required string args ) {
		var result      = "";
		var config      = $getPresideCategorySettings( "asset-manager" );
		var timeout     = Val( config.imagemagick_timeout     ?: 30 );
		var concurrency = Val( config.imagemagick_concurrency ?: 5  );
		var binDir      = Trim( config.imagemagick_path ?: "" );
		var start       = getTickCount();

		if ( concurrency > 0 ) {
			while( concurrency <= _getActiveOperationCount() ) {
				sleep( 100 );
				if ( getTickCount() - start > timeout * 1000 ) {
					throw( type="imagemagick.too.busy", message="Giving up attempting image operation because too many active image operations", detail="Command: [#arguments.command# #arguments.args#]" );
				}
			}
		}

		if ( concurrency > 0 ) {
			var operationKey = _registerOperation( timeout );
		}

		try {
			if ( Len( binDir ) ) {
				binDir = Replace( binDir, "\", "/", "all" );
				binDir = ReReplace( binDir, "([^/])$", "\1/" );
			}

			execute name      = binDir & arguments.command
			        arguments = arguments.args
			        timeout   = Val( config.imagemagick_timeout ?: 30 )
			        variable  = "result";

			return result;
		} catch ( any e ) {
			rethrow;
		} finally {
			if ( concurrency > 0 ) {
				_deRegisterOperation( operationKey );
			}
		}
	}

	private string function _cfToImQuality( required string cfInterpolation ) {
		switch( arguments.cfInterpolation ) {
			case "highestQuality":
				return "-filter lanczos -define filter:support=2 -quality 90";

			case "highQuality":
			case "mediumPerformance":
				return "-filter lanczos -define filter:support=2 -quality 82";


			case "nearest":
			case "bicubic":
			case "bilinear":
			case "highestPerformance":
				return "-filter triangle -define filter:support=3 -quality 75";
		}

		return "-filter triangle -define filter:support=3 -quality 82";
	}

	private void function _checkResize( required string destinationFile, required numeric width, required numeric height ) {
		var rawInfo    = Trim( _exec( command="identify", args='-format "%wx%h" "#arguments.destinationFile#"' ) );
		var dimensions = {};
		var failure    = false;

		if ( ReFindNoCase( "^[0-9]+x[0-9]+$", rawInfo ) ) {
			dimensions = {
				  width  = ListFirst( rawInfo, "x" )
				, height = ListLast( rawInfo, "x" )
			};

			if ( ( arguments.width && dimensions.width != arguments.width ) || ( arguments.height && dimensions.height != arguments.height ) ) {
				throw( type="imagemagick.resize.failure",  message="Image resize operation failed. Expected dimensions [#arguments.width#x#arguments.height#]. Received dimensions: [#rawInfo#]" );
			}
		} else {
			throw( type="imagemagick.resize.failure",  message="Image resize operation failed. Expected dimensions [#arguments.width#x#arguments.height#]. Generated image dimensions could not be read, received instead [#rawInfo#]" );
		}
	}

	private string function _registerOperation( required numeric timeoutInSeconds ) {
		lock name=_getActiveOperationsLockName() type="exclusive" timeout=1 {
			var operations = _getActiveOperations();
			var key        = CreateUUId();

			operations[ key ] = GetTickCount() + ( timeoutInSeconds * 1000 );

			return key;
		}
	}

	private void function _deRegisterOperation( required string key ) {
		lock name=_getActiveOperationsLockName() type="exclusive" timeout=1 {
			var operations = _getActiveOperations();

			operations.delete( arguments.key );
		}
	}

	private numeric function _getActiveOperationCount() {
		lock name=_getActiveOperationsLockName() type="readonly" timeout=1 {
			var operations = _getActiveOperations();
			var ticksNow   = GetTickCount();

			for ( var key in operations ) {
				if ( operations[ key ] < ticksNow ) {
					operations.delete[ key ];
				}
			}

			return operations.count();
		}
	}

// GETTERS AND SETTERS
	private struct function _getActiveOperations() {
		return _activeOperations;
	}
	private void function _setActiveOperations( required struct activeOperations ) {
		_activeOperations = arguments.activeOperations;
	}

	private string function _getActiveOperationsLockName() {
		return _activeOperationsLockName;
	}
	private void function _setActiveOperationsLockName( required string activeOperationsLockName ) {
		_activeOperationsLockName = arguments.activeOperationsLockName;
	}

}