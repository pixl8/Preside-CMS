/**
 * Provides image manipulation logic using ImageMagick
 *
 * @autodoc        true
 * @singleton      true
 * @presideservice true
 * @feature        assetManager
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

	public void function resize(
		  required string  filePath
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
		,          string  gravity             = 'center'
		,          string  focalPoint          = ""
		,          struct  cropHintArea        = {}
		,          struct  fileProperties      = {}
	) {

		var currentImageInfo  = JavaImageMetaReader::readMeta( arguments.filePath );
		var isSvg             = ( fileProperties.fileExt ?: "" ) == "svg";
		var isJpg             = ReFindNoCase( "^jpe?g$", fileProperties.fileExt ?: "" );

		if ( isJpg ) {
			autoCorrectImageOrientation( arguments.filePath );
		} else if ( isSvg ) {
			_getSvgToPngService().svgToPng( arguments.filePath, arguments.width, arguments.height );
		}

		var tmpDestFilePath = GetTempFile( GetTempDirectory(), "mgk" );

		try {
			imageMagickResize(
				  sourceFile      = arguments.filePath
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

			FileMove( tmpDestFilePath, arguments.filePath );
		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			_deleteFile( tmpDestFilePath );
		}

		currentImageInfo      = JavaImageMetaReader::readMeta( arguments.filePath );
		fileProperties.width  = currentImageInfo.width;
		fileProperties.height = currentImageInfo.height;
	}

	public void function shrinkToFit(
		  required string  filePath
		, required numeric width
		, required numeric height
		,          string  quality        = "highPerformance"
		,          string  paddingColour  = ""
		,          struct  fileProperties = {}
	) {
		var currentImageInfo  = JavaImageMetaReader::readMeta( arguments.filePath );
		var isSvg             = ( fileProperties.fileExt ?: "" ) == "svg";
		var isJpg             = ReFindNoCase( "^jpe?g$", fileProperties.fileExt ?: "" );

		if ( isJpg ) {
			autoCorrectImageOrientation( arguments.filePath );
		} else if ( isSvg ) {
			_getSvgToPngService().svgToPng( arguments.filePath, arguments.width, arguments.height );
		}

		var tmpDestFilePath   = GetTempFile( GetTempDirectory(), "mgk" );
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

		try {
			imageMagickResize(
				  sourceFile      = arguments.filePath
				, destinationFile = tmpDestFilePath
				, qualityArgs     = _cfToImQuality( arguments.quality )
				, width           = shrinkToWidth
				, height          = shrinkToHeight
				, expand          = true
				, crop            = false
				, paddingColour   = arguments.paddingColour
				, paddedWidth     = len( arguments.paddingColour ) ? arguments.width  : 0
				, paddedHeight    = len( arguments.paddingColour ) ? arguments.height : 0
			);
			FileMove( tmpDestFilePath, arguments.filePath )

		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			_deleteFile( tmpDestFilePath );
		}

		currentImageInfo      = JavaImageMetaReader::readMeta( arguments.filePath );
		fileProperties.width  = currentImageInfo.width;
		fileProperties.height = currentImageInfo.height;
	}

	public void function pdfPreview(
		  required string filePath
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
		,          struct fileProperties = {}
	) {
		var imagePrefix    = CreateUUId();
		var tmpDir         = GetTempDirectory();
		var tmpFilePathPDF = GetTempFile( tmpDir, "mgk" ) & ".pdf";
		var tmpFilePathJpg = GetTempFile( tmpDir, "mgk" ) & ".jpg";
		var args           = '"#tmpFilePathPDF#[0]" -density 100 -colorspace sRGB -flatten "#tmpFilePathJpg#"';

		FileCopy( arguments.filePath, tmpFilePathPdf );

		try {
			_exec( command="convert", args=args );

			FileMove( tmpFilePathJpg, arguments.filePath );

			var imageInfo          = JavaImageMetaReader::readMeta( arguments.filePath );
			fileProperties.width   = imageInfo.width;
			fileProperties.height  = imageInfo.height;
			fileProperties.fileExt = "jpg";

		} catch( any e ) {
			rethrow;
		} finally {
			_deleteFile( tmpFilePathPDF );
			_deleteFile( tmpFilePathJpg );
		}
	}

	public string function imageMagickResize(
		  required string  sourceFile
		, required string  destinationFile
		, required string  qualityArgs
		, required numeric width
		, required numeric height
		,          boolean expand        = false
		,          boolean crop          = false
		,          string  gravity       = 'center'
		,          string  focalPoint    = ""
		,          struct  cropHintArea  = {}
		,          struct  imageInfo     = {}
		,          string  paddingColour = ""
		,          numeric paddedWidth   = 0
		,          numeric paddedHeight  = 0
	) {
		var defaultSettings = '-coalesce -auto-orient -unsharp 0.25x0.25+24+0.065 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -colorspace sRGB -strip -background "{background}"';
		var args            = '"#arguments.sourceFile#" #arguments.qualityArgs# #defaultSettings#{preCrop} -thumbnail #( arguments.width ? arguments.width : '' )#x#( arguments.height ? arguments.height : '' )#';
		var interlace       = $getPresideSetting( "asset-manager", "imagemagick_interlace" );
		var extent          = " -extent #arguments.width#x#arguments.height#";
		var offset          = "+0+0";
		var preCrop         = "";
		var background      = "none";

		if ( arguments.expand ) {
			if ( arguments.crop ) {
				args &= "^";
			}
			if ( !arguments.cropHintArea.isEmpty() && !imageInfo.isEmpty() ) {
				gravity = "NorthWest";
				preCrop = " -extent #arguments.cropHintArea.width#x#arguments.cropHintArea.height#+#arguments.cropHintArea.x#+#arguments.cropHintArea.y#";
				extent  = "";
				offset  = "";
			} else if ( len( arguments.focalPoint ) && !imageInfo.isEmpty() ) {
				gravity = "NorthWest";
				offset  = _calculateFocalPointOffset(
					  originalWidth  = imageInfo.width
					, originalHeight = imageInfo.height
					, newWidth       = arguments.width
					, newHeight      = arguments.height
					, focalPoint     = arguments.focalPoint
				);
			} else if ( arguments.paddingColour != "" && arguments.paddedWidth && arguments.paddedHeight ) {
				background = _getPaddingColour( arguments.sourceFile, arguments.paddingColour );
				gravity    = "Center";
				extent     = " -extent #arguments.paddedWidth#x#arguments.paddedHeight#";
				offset     = "";
			}
			args &= " -gravity #gravity##extent##offset#";
		} else if ( arguments.width && arguments.height ) {
			args &= "!";
		}
		args = args.replace( "{preCrop}", preCrop );
		args = args.replace( "{background}", background );

		interlace = ( IsBoolean( interlace ) && interlace ) ? "line" : "none";
		args &= " -interlace #interlace#";
		args &= " " & '"#arguments.destinationFile#"';

		_exec( command="convert", args=args );

		_checkResize( argumentCollection=arguments );

		return arguments.destinationFile;
	}

	public void function autoCorrectImageOrientation( required string filePath ) {
		var rawOrientation = Trim( _exec( command="identify", args='-format "%[orientation]" "#arguments.filePath#"' ) );
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
			_exec( command="convert", args="#arguments.filePath# #imageQuality# #defaultSettings# #tmpDestinationFilePath#" );

			FileMove( tmpDestinationFilePath, arguments.filePath );
		}
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

	private string function _getPaddingColour( required string sourceFile, required string paddingColour ) {
		if ( arguments.paddingColour == "auto" ) {
			return _exec( command="convert", args='#arguments.sourceFile#[1x1+0+0] -format "%[pixel:p{40,30}]" info:' );
		} else if ( reFindNoCase( "^[0-9a-f]{6}$", arguments.paddingColour ) ) {
			return "###arguments.paddingColour#";
		}

		return "none";
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

	private void function _deleteFile( required string path ) {
		if ( FileExists( arguments.path ) ) {
			try {
				FileDelete( arguments.path );
			} catch( any e ) {
				if ( FileExists( arguments.path ) ) {
					rethrow;
				}
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