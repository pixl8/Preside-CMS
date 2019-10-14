/**
 * Provides image manipulation logic using ImageMagick
 *
 * @autodoc
 * @singleton
 * @presideservice
 *
 */
component displayname="ImageMagick"  {

	/**
	 * @svgToPngService.inject svgToPngService
	 *
	 */
	public any function init( required any svgToPngService ) {
		_setSvgToPngService( arguments.svgToPngService );
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
		,          string  gravity             = 'center'
		,          string  focalPoint          = ""
		,          struct  cropHintArea        = {}
		,          struct  fileProperties      = {}
	) {

		var imageBinary       = arguments.asset;
		var currentImageInfo  = getImageInformation( imageBinary );
		var isSvg             = ( fileProperties.fileExt ?: "" ) == "svg";

		imageBinary = autoCorrectImageOrientation( imageBinary );

		var tmpDir            = _createTmpDir();
		var tmpSourceFilePath = getTempFile( tmpDir, "mgk" );
		var tmpDestFilePath   = getTempFile( tmpDir, "mgk" );

		if ( isSvg ) {
			imageBinary = _getSvgToPngService().SVGToPngBinary( imageBinary, arguments.width, arguments.height );
			fileProperties.fileExt = "png";
		}

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
				, gravity         = arguments.gravity
				, focalPoint      = arguments.focalPoint
				, cropHintArea    = arguments.cropHintArea
				, imageInfo       = currentImageInfo
			);

			imageBinary = FileReadBinary( tmpDestFilePath );
		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			_deleteDir( tmpDir );
		}

		return imageBinary;
	}

	public binary function pdfPreview(
		  required binary asset
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
		,          struct fileProperties = {}
	) {
		var imagePrefix    = CreateUUId();
		var tmpDir         = _createTmpDir();
		var tmpFilePathPDF = GetTempFile( tmpDir, "mgk" );
		var tmpFilePathJpg = GetTempFile( tmpDir, "mgk" ) & ".jpg";
		var args           = '"#tmpFilePathPDF#[0]" -density 100 -colorspace sRGB -flatten "#tmpFilePathJpg#"';

		FileWrite( tmpFilePathPDF, arguments.asset );

		_exec( command="convert", args=args );

		var binary = FileReadBinary( tmpFilePathJpg );

		_deleteDir( tmpDir );

		arguments.fileProperties.fileExt = "jpg";

		return binary;
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality = "highPerformance"
		,          struct  fileProperties = {}
	) {
		var imageBinary = arguments.asset;
		var isSvg       = ( fileProperties.fileExt ?: "" ) == "svg";

		imageBinary = autoCorrectImageOrientation( imageBinary );

		var currentImageInfo  = getImageInformation( imageBinary );
		var tmpDir            = _createTmpDir();
		var tmpSourceFilePath = GetTempFile( tmpDir, "mgk" );
		var tmpDestFilePath   = GetTempFile( tmpDir, "mgk" );


		var shrinkToWidth     = arguments.width;
		var shrinkToHeight    = arguments.height;
		var widthChangeRatio  = currentImageInfo.width / shrinkToWidth;
		var heightChangeRatio = currentImageInfo.height / shrinkToHeight;


		if ( widthChangeRatio > heightChangeRatio ) {
			shrinkToHeight = 0;
		} else {
			shrinkToWidth = 0;
		}

		if ( currentImageInfo.width <= arguments.width && currentImageInfo.height <= arguments.height ) {
			shrinkToWidth  = currentImageInfo.width;
			shrinkToHeight = currentImageInfo.height;
		}

		if ( isSvg ) {
			imageBinary = _getSvgToPngService().SVGToPngBinary( imageBinary, shrinkToWidth, shrinkToHeight );
			fileProperties.fileExt = "png";
		}

		FileWrite( tmpSourceFilePath, imageBinary );

		try {
			imageMagickResize(
				  sourceFile      = tmpSourceFilePath
				, destinationFile = tmpDestFilePath
				, qualityArgs     = _cfToImQuality( arguments.quality )
				, width           = shrinkToWidth
				, height          = shrinkToHeight
				, expand          = true
				, crop            = false
			);

			imageBinary = FileReadBinary( tmpDestFilePath );
		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			_deleteDir( tmpDir );
		}

		return imageBinary;
	}

	public string function imageMagickResize(
		  required string  sourceFile
		, required string  destinationFile
		, required string  qualityArgs
		, required numeric width
		, required numeric height
		,          boolean expand       = false
		,          boolean crop         = false
		,          string  gravity      = 'center'
		,          string  focalPoint   = ""
		,          struct  cropHintArea = {}
		,          struct  imageInfo    = {}
	) {
		var defaultSettings = "-coalesce -auto-orient -unsharp 0.25x0.25+24+0.065 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -colorspace sRGB -strip -background none";
		var args            = '"#arguments.sourceFile#" #arguments.qualityArgs# #defaultSettings#{preCrop} -thumbnail #( arguments.width ? arguments.width : '' )#x#( arguments.height ? arguments.height : '' )#';
		var interlace       = $getPresideSetting( "asset-manager", "imagemagick_interlace" );
		var extent          = " -extent #arguments.width#x#arguments.height#";
		var offset          = "+0+0";
		var preCrop         = "";

		if ( arguments.expand ) {
			if ( arguments.crop ) {
				args &= "^";
			}
			if ( !arguments.cropHintArea.isEmpty() && !imageInfo.isEmpty() ) {
				gravity = "NorthWest";
				preCrop = " -extent #arguments.cropHintArea.width#x#arguments.cropHintArea.height#+#arguments.cropHintArea.x#+#arguments.cropHintArea.y#";
				extent  = "";
				offset  = ""
			} else if ( len( arguments.focalPoint ) && !imageInfo.isEmpty() ) {
				gravity = "NorthWest";
				offset  = _calculateFocalPointOffset(
					  originalWidth  = imageInfo.width
					, originalHeight = imageInfo.height
					, newWidth       = arguments.width
					, newHeight      = arguments.height
					, focalPoint     = arguments.focalPoint
				);
			}
			args &= " -gravity #gravity##extent##offset#";
		} else if ( arguments.width && arguments.height ) {
			args &= "!";
		}
		args = args.replace( "{preCrop}", preCrop );

		interlace = ( IsBoolean( interlace ) && interlace ) ? "line" : "none";
		args &= " -interlace #interlace#";
		args &= " " & '"#arguments.destinationFile#"';

		_exec( command="convert", args=args );

		_checkResize( argumentCollection=arguments );

		return arguments.destinationFile;
	}

	public struct function getImageInformation( required binary asset ) {
		var tmpFilePath = GetTempFile( GetTempDirectory(), "mgk" );
		var imageBinary = autoCorrectImageOrientation( arguments.asset );

		FileWrite( tmpFilePath, imageBinary );

		var rawInfo = Trim( _exec( command="identify", args='-format "%[width]x%[height]" "#tmpFilePath#"[0]' ) );

		FileDelete( tmpFilePath );

		if ( ReFindNoCase( "^[0-9]+x[0-9]+$", rawInfo ) ) {
			return {
				  width  = ListFirst( rawInfo, "x" )
				, height = ListLast( rawInfo, "x" )
			};
		}

		throw( type="AssetTransformer.shrinkToFit.notAnImage" );
	}

	public binary function autoCorrectImageOrientation( required binary asset ) {
		var tmpSourceFilePath = GetTempFile( GetTempDirectory(), "mgk" );
		var imageBinary = arguments.asset;

		FileWrite( tmpSourceFilePath, imageBinary );
		var rawOrientation = Trim( _exec( command="identify", args='-format "%[orientation]" "#tmpSourceFilePath#"' ) );
		var convertOrientation = false;

		switch ( rawOrientation ) {
			case "BottomRight":
				convertOrientation = true;
				break;
			case "RightTop":
				convertOrientation = true;
				break;
			case "LeftBottom":
				convertOrientation = true;
				break;
		}

		if ( convertOrientation ) {
			var tmpDestinationFilePath = GetTempFile( GetTempDirectory(), "mgk" );
			var imageQuality = _cfToImQuality( "highestQuality" );
			var defaultSettings = "-auto-orient -unsharp 0.25x0.25+24+0.065 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -colorspace sRGB -strip";
			_exec( command="convert", args="#tmpSourceFilePath# #imageQuality# #defaultSettings# #tmpDestinationFilePath#" );
			imageBinary = fileReadBinary( tmpDestinationFilePath );
			fileDelete( tmpDestinationFilePath );
		}

		fileDelete( tmpSourceFilePath );

		return imageBinary;
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
		var rawInfo    = Trim( _exec( command="identify", args='-format "%[width]x%[height]" "#arguments.destinationFile#"[0]' ) );
		var dimensions = {};
		var failure    = false;

		if ( ReFindNoCase( "^[0-9]+x[0-9]+$", rawInfo ) ) {
			dimensions = {
				  width  = ListFirst( rawInfo, "x" )
				, height = ListLast( rawInfo, "x" )
			};

			if ( ( arguments.width && _dimensionsNotCloseEnough( dimensions.width, arguments.width ) ) || ( arguments.height && _dimensionsNotCloseEnough( dimensions.height, arguments.height ) ) ) {
				throw( type="imagemagick.resize.failure",  message="Image resize operation failed. Expected dimensions [#arguments.width#x#arguments.height#]. Received dimensions: [#rawInfo#]" );
			}
		} else {
			throw( type="imagemagick.resize.failure",  message="Image resize operation failed. Expected dimensions [#arguments.width#x#arguments.height#]. Generated image dimensions could not be read, received instead [#rawInfo#]" );
		}
	}

	private string function _calculateFocalPointOffset(
		  required numeric originalWidth
		, required numeric originalHeight
		, required numeric newWidth
		, required numeric newHeight
		, required string  focalPoint
	) {
		var heightRatio   = newHeight / originalHeight;
		var widthRatio    = newWidth  / originalWidth;
		var scale         = max( heightRatio, widthRatio );
		var interimHeight = int( originalHeight * scale );
		var interimWidth  = int( originalWidth  * scale );
		var originX       = 0;
		var originY       = 0;
		var cropCentreX   = int( arguments.newWidth  / 2 );
		var cropCentreY   = int( arguments.newHeight / 2 );
		var focalPointX   = int( listFirst( arguments.focalPoint ) * interimWidth  );
		var focalPointY   = int( listLast(  arguments.focalPoint ) * interimHeight );

		if ( focalPointX > cropCentreX ) {
			originX = min( focalPointX - cropCentreX, interimWidth - arguments.newWidth );
		}
		if ( focalPointY > cropCentreY ) {
			originY = min( focalPointY - cropCentreY, interimHeight - arguments.newHeight );
		}

		return "+#originX#+#originY#";
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
					operations.delete( key );
				}
			}

			return operations.count();
		}
	}

	private boolean function _dimensionsNotCloseEnough( required numeric dimension1, required numeric dimension2 ) {
		return abs( arguments.dimension1 - arguments.dimension2 ) > 2; // within 2px is fine
	}

	private string function _createTmpDir() {
		var dir = GetTempDirectory() & "imgmgkoperation-#CreateUUId()#";

		DirectoryCreate( dir );

		return dir;
	}

	private void function _deleteDir( required string dir ) {
		try {
			DirectoryDelete( dir, true );
		} catch( any e ) {
			if ( DirectoryExists( dir ) ) {
				rethrow;
			}
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

	private any function _getSvgToPngService() {
	    return _svgToPngService;
	}
	private void function _setSvgToPngService( required any svgToPngService ) {
	    _svgToPngService = arguments.svgToPngService;
	}

}