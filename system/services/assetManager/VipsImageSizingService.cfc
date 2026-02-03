/**
 * @presideService true
 * @singleton      true
 * @feature        assetManager
 */
component {

// CONSTRUCTOR
	/**
	 * @svgToPngService.inject svgToPngService
	 * @vipsSettings.inject    coldbox:setting:assetmanager.vips
	 *
	 */
	public any function init( required any svgToPngService, required struct vipsSettings ) {
		_setSvgToPngService( arguments.svgToPngService );
		_setBinDir( arguments.vipsSettings.binDir ?: "/usr/bin" );
		_setTimeout( Val( arguments.vipsSettings.timeout ?: 60 ) );
		_setEnabled( FileExists( _getBinDir() & "vips" ) );

		_enableFeaturesByVersion( {
			smartcrop = "8.5.0"
		} );

		return this;
	}

// PUBLIC API METHODS
	public void function resize(
		  required string  filePath
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
		,          string  focalPoint          = ""
		,          boolean autoFocalPoint      = false
		,          struct  cropHintArea        = {}
		,          boolean useCropHint         = false
		,          string  outputFormat        = ""
		,          struct  fileProperties      = {}
	) {
		arguments.autoFocalPoint = arguments.autoFocalPoint && _featureIsEnabled( "smartcrop" );

		var originalFileExt = fileProperties.fileExt ?: "";
		var isSvg           = originalFileExt == "svg";
		var isGif           = originalFileExt == "gif";

		if ( isSvg ) {
			_getSvgToPngService().SvgToPng( arguments.filePath, arguments.width, arguments.height );
			fileProperties.fileExt = "png";

			return;
		}
		if ( len( arguments.outputFormat ) ) {
			fileProperties.fileExt = arguments.outputFormat;
		}

		var sourceFile         = arguments.filePath;
		var targetFile         = sourceFile & "_#CreateUUId()#.#( fileProperties.fileExt ?: '' )#";
		var imageInfo          = getImageInformation( filePath=sourceFile );
		var vipsQuality        = _cfToVipsQuality( arguments.quality, fileProperties.fileExt ?: "" );
		var requiresConversion = ( fileProperties.fileExt ?: "" ) != originalFileExt;

		if ( imageInfo.width == arguments.width && imageInfo.height == arguments.height && !requiresConversion ) {
			return;
		}

		FileCopy( sourceFile, targetFile );
		if ( imageInfo.requiresOrientation || isGif ) {
			targetFile = _autoRotate( targetFile, vipsQuality );
		}

		if ( !arguments.height ) {
			targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
		} else if ( !arguments.width ) {
			targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
		} else {
			var requiresResize    = true;
			var useAutoFocalPoint = false;

			if ( arguments.useCropHint && !arguments.cropHintArea.isEmpty() ) {
				targetFile = _crop( targetFile, imageInfo, arguments.cropHintArea, vipsQuality );
				imageInfo  = getImageInformation( filePath=targetFile );
			} else {
				if ( maintainAspectRatio ) {
					var currentAspectRatio = imageInfo.width / imageInfo.height;
					var targetAspectRatio  = arguments.width / arguments.height;
					useAutoFocalPoint      = arguments.autoFocalPoint && !len( arguments.focalPoint );

					if ( targetAspectRatio != currentAspectRatio && !useAutoFocalPoint ) {
						if ( currentAspectRatio > targetAspectRatio ) {
							targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
						} else {
							targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
						}

						imageInfo = getImageInformation( filePath=targetFile );
						targetFile = _cropToFocalPoint( argumentCollection=arguments, targetFile=targetFile, imageInfo=imageInfo, vipsQuality=vipsQuality );
						requiresResize = false;
					}
				}
			}

			if ( requiresResize ) {
				targetFile = _thumbnail( targetFile, imageInfo, arguments.width, arguments.height, vipsQuality, useAutoFocalPoint );
			}
		}

		FileMove( targetFile, arguments.filePath );
	}

	public void function shrinkToFit(
		  required string  filePath
		, required numeric width
		, required numeric height
		,          string  quality            = "highPerformance"
		,          string  outputFormat       = ""
		,          string  paddingColour      = ""
		,          struct  fileProperties     = {}
		,          numeric paddingColourAlpha = 255
	) {
		var originalFileExt = fileProperties.fileExt ?: "";
		var isSvg           = originalFileExt == "svg";
		var isGif           = originalFileExt == "gif";

		if ( isSvg ) {
			_getSvgToPngService().SvgToPng( arguments.filePath, arguments.width, arguments.height );
			fileProperties.fileExt = "png";

			return;
		}
		if ( len( arguments.outputFormat ) ) {
			fileProperties.fileExt = arguments.outputFormat;
		}

		var sourceFile         = arguments.filePath;
		var targetFile         = sourceFile & "_#CreateUUId()#.#( fileProperties.fileExt ?: '' )#";
		var imageInfo          = getImageInformation( filePath=sourceFile );
		var vipsQuality        = _cfToVipsQuality( arguments.quality, fileProperties.fileExt ?: "" );
		var requiresConversion = ( fileProperties.fileExt ?: "" ) != originalFileExt;

		if ( imageInfo.width <= arguments.width && imageInfo.height <= arguments.height && !requiresConversion ) {
			return;
		}

		FileCopy( sourceFile, targetFile );
		if ( imageInfo.requiresOrientation || isGif ) {
			targetFile = _autoRotate( targetFile, vipsQuality );
			imageInfo  = getImageInformation( filePath=targetFile );
		}

		var currentAspectRatio = imageInfo.width / imageInfo.height;
		var targetAspectRatio  = arguments.width / arguments.height;
		var requiresShrinking  = imageInfo.width > arguments.width || imageInfo.height > arguments.height;

		if ( requiresShrinking ) {
			if ( targetAspectRatio == currentAspectRatio ) {
				targetFile = _thumbnail( targetFile, imageInfo, arguments.width, arguments.height, vipsQuality );
			} else if ( currentAspectRatio > targetAspectRatio ) {
				targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
			} else {
				targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
			}

			imageInfo = getImageInformation( filePath=targetFile );

			if ( imageInfo.width > arguments.width ) {
				targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
			} else if ( imageInfo.height > arguments.height ){
				targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
			}
		} else if ( requiresConversion ) {
			targetFile = _thumbnail( targetFile, imageInfo, imageInfo.width, imageInfo.height, vipsQuality );
		}

		if ( len( arguments.paddingColour ) ) {
			targetFile = _padding(
				  targetFile         = targetFile
				, width              = arguments.width
				, height             = arguments.height
				, vipsQuality        = vipsQuality
				, paddingColour      = arguments.paddingColour
				, paddingColourAlpha = arguments.paddingColourAlpha
			);
		}

		FileMove( targetFile, arguments.filePath );
	}

	public void function pdfPreview(
		  required string filePath
		,          string scale
		,          string resolution     = 144
		,          string format
		,          string pages
		,          string transparent
		,          struct fileProperties = {}
	) {
		var imagePrefix    = CreateUUId();
		var tmpDir         = GetTempDirectory();
		var tmpFilePathPdf = tmpDir & "vips#createUUID()#.pdf";
		var tmpFilePathJpg = tmpDir & "vips#createUUID()#.jpg";
		var args           = '"#tmpFilePathPdf#"[dpi=#arguments.resolution#] --size 1692x2400 --eprofile srgb -o "#tmpFilePathJpg#"[strip,optimize_coding]';

		FileCopy( arguments.filePath, tmpFilePathPdf );

		try {
			_exec( command="vipsthumbnail", args=args );

			FileMove( tmpFilePathJpg, arguments.filePath );

			var imageInfo                    = getImageInformation( arguments.filePath );
			arguments.fileProperties.width   = imageInfo.width;
			arguments.fileProperties.height  = imageInfo.height;
			arguments.fileProperties.fileExt = "jpg";

		} catch( any e ) {
			rethrow;
		} finally {
			_deleteFile( tmpFilePathPdf );
			_deleteFile( tmpFilePathJpg );
		}
	}

	public struct function getImageInformation( required string filePath ) {
		var rawInfo = Trim( _exec( command="vipsheader", args='-a "#arguments.filePath#"' ) );
		var info = {};
		var key = "";
		var value = "";

		for( var line in ListToArray( rawInfo, Chr(10) & Chr(13) ) ) {
			if ( ListLen( line, ":" ) > 1 ) {
				info[ Trim( ListFirst( line, ":" ) ) ] = Trim( ListRest( line, ":" ) );
			}
		}

		if ( Val( info.width ?: "" ) && Val( info.height ?: "" ) ) {
			var orientation = Val( info.orientation ?: ( info[ "exif-ifd0-Orientation" ] ?: 1 ) );

			if ( orientation == 8 || orientation == 6 ) {
				info.requiresOrientation = true;
				var tmpWidth = info.width;
				info.width = info.height;
				info.height = tmpWidth;
			} else {
				info.requiresOrientation = false;
			}

			return info;
		}

		throw( type="AssetTransformer.notAnImage" );
	}

	public boolean function enabled() {
		return _getEnabled();
	}

// PRIVATE HELPERS
	private string function _exec( required string command, required string args ) {
		var result  = "";

		execute name      = _getBinDir() & arguments.command
				arguments = arguments.args
				timeout   = _getTimeout()
				variable  = "result";

		return result;
	}

	private number function _int( required numeric value ) {
		return numberFormat( arguments.value, "0" );
	}

	private string function _cfToVipsQuality( required string quality, required string fileExtension ) {
		var pngExtensions = [ "gif", "png" ];

		if ( ArrayFindNoCase( [ "gif", "png" ], arguments.fileExtension ) ) {
			switch( arguments.quality ) {
				case "highestQuality":
					return "compression=3";

				case "highQuality":
				case "mediumPerformance":
					return "compression=5";

				case "mediumQuality":
				case "highPerformance":
					return "compression=6";

				case "highestPerformance":
					return "compression=9";
				default:
					return "compression=6";
			}
		}

		switch( arguments.quality ) {
			case "highestQuality":
				return "Q=95";

			case "highQuality":
			case "mediumPerformance":
				return "Q=85";

			case "mediumQuality":
			case "highPerformance":
				return "Q=80";

			case "highestPerformance":
				return "Q=75";
		}

		return "Q=80";
	}

	private struct function _getFocalPointRectangle(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  focalPoint
	) {
		var originX     = 0;
		var originY     = 0;
		var cropCentreX = originX + _int( arguments.width  / 2 );
		var cropCentreY = originY + _int( arguments.height / 2 );
		var focalPoint  = len( arguments.focalPoint ) ? arguments.focalPoint : "0.5,0.5";
		var focalPointX = _int( listFirst( focalPoint ) * imageInfo.width  );
		var focalPointY = _int( listLast(  focalPoint ) * imageInfo.height );

		if ( focalPointX > cropCentreX ) {
			originX = min( originX + ( focalPointX - cropCentreX ), imageInfo.width - arguments.width );
		}
		if ( focalPointY > cropCentreY ) {
			originY = min( originY + ( focalPointY - cropCentreY ), imageInfo.height - arguments.height );
		}

		return {
			  x      = originX
			, y      = originY
			, width  = arguments.width
			, height = arguments.height
		};
	}

	private string function _scaleToFit(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  vipsQuality
	) {
		if ( !arguments.height ) {
			arguments.height = Ceiling( imageInfo.height * ( arguments.width / imageInfo.width ) );
		} else if ( !arguments.width ) {
			arguments.width = Ceiling( imageInfo.width * ( arguments.height / imageInfo.height ) );
		}

		return _thumbnail( argumentCollection=arguments );
	}

	private string function _thumbnail(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  vipsQuality
		,          boolean smartcrop = false
	){
		arguments.smartcrop = arguments.smartcrop && _featureIsEnabled( "smartcrop" );

		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "tn_" );
		var outputFormat  = "tn_%s.#ListLast( newTargetFile, '.' )#";
		var size          = "#_int( arguments.width )#x#_int( arguments.height )#";
		var smartcrop     = arguments.smartcrop ? "--smartcrop attention" : "";

		try {
			try {
				_exec( "vipsthumbnail", """#arguments.targetFile#"" -s #size# #smartcrop# --eprofile srgb -d -o ""#outputFormat#[#arguments.vipsQuality#,strip]""" );
			} catch( any e ) {
				if ( e.detail contains "no input profile" ) {
					_exec( "vipsthumbnail", """#arguments.targetFile#"" -s #size# #smartcrop# -d -o ""#outputFormat#[#arguments.vipsQuality#,strip]""" );
				} else {
					rethrow;
				}
			}
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private string function _padding(
		  required string  targetFile
		, required numeric width
		, required numeric height
		, required string  vipsQuality
		, required string  paddingColour
		,          numeric paddingColourAlpha = 255
	){
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "tn_" );
		var size          = "#_int( arguments.width )# #_int( arguments.height )#";
		var background    = _getPaddingColour(
			  targetFile         = arguments.targetFile
			, paddingColour      = arguments.paddingColour
			, paddingColourAlpha = arguments.paddingColourAlpha
		);

		try {
			_exec( "vips", 'gravity "#arguments.targetFile#" "#newTargetFile#[#arguments.vipsQuality#]" VIPS_COMPASS_DIRECTION_CENTRE #size# #background# --extend VIPS_EXTEND_BACKGROUND' );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private string function _getPaddingColour(
		  required string  targetFile
		, required string  paddingColour
		,          numeric paddingColourAlpha = 255
	) {
		var backgroundRgb     = "";
		var currentBackground = trim( _exec( "vips", 'getpoint "#arguments.targetFile#" 0 0' ) );

		if ( arguments.paddingColour == "auto" ) {
			backgroundRgb = currentBackground;
		} else if ( reFindNoCase( "^[0-9a-f]{6}$", arguments.paddingColour ) ) {
			var backgroundRgbParts = [
				  inputBaseN( mid( arguments.paddingColour, 1, 2 ), 16 )
				, inputBaseN( mid( arguments.paddingColour, 3, 2 ), 16 )
				, inputBaseN( mid( arguments.paddingColour, 5, 2 ), 16 )
			];
			if ( ListLen( currentBackground, " " ) == 4 ) {
				arrayAppend( backgroundRgbParts, arguments.paddingColourAlpha );
			}
			backgroundRgb = arrayToList( backgroundRgbParts, " " );
		}

		if ( len( backgroundRgb ) ) {
			return '--background "#backgroundRgb#"';
		}

		return "";
	}

	private string function _crop(
		  required string  targetFile
		, required struct  imageInfo
		, required struct  cropArea
		, required string  vipsQuality
	) {
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "crop_" );
		try {
			_exec( "vips", 'crop "#targetFile#" """#newTargetFile#[#arguments.vipsQuality#,strip]""" #_int( cropArea.x )# #_int( cropArea.y )# #_int( cropArea.width )# #_int( cropArea.height )#' );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private string function _cropToFocalPoint(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  focalPoint
		, required boolean autoFocalPoint
		, required string  vipsQuality
	) {
		if ( autoFocalPoint && !len( focalPoint ) ) {
			return targetFile;
		}
		var rectangle = _getFocalPointRectangle( argumentCollection=arguments );

		if ( rectangle.x < 0 || ( rectangle.x + rectangle.width ) > imageInfo.width ) {
			return targetFile;
		}
		if ( rectangle.y < 0 || ( rectangle.y + rectangle.height ) > imageInfo.height ) {
			return targetFile;
		}

		return _crop( targetFile, imageInfo, rectangle, vipsQuality );
	}

	private string function _autoRotate( required string targetFile, required string vipsQuality ) {
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "crop_" ).reReplace( "\.gif$", ".png" );
		try {
			_exec( "vips", 'autorot "#targetFile#" """#newTargetFile#[#arguments.vipsQuality#]"""' );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
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

	private string function _pathFileNamePrefix( required string path, required string prefix ) {
		var fileName = ListLast( arguments.path, "\/" );
		var dirName = GetDirectoryFromPath( arguments.path );

		return dirName & arguments.prefix & fileName;
	}

	private void function _enableFeaturesByVersion( required struct features ) {
		_enabledFeatures = {};

		if ( enabled() ) {
			var vipsVersion  = _getVipsVersion();

			for( var feature in arguments.features ) {
				_enabledFeatures[ feature ] = _compareVersions( vipsVersion, arguments.features[ feature ] ) != -1;
			}
		}
	}

	private boolean function _featureIsEnabled( required string feature ) {
		return $helpers.isTrue( _enabledFeatures[ arguments.feature ] ?: "" );
	}

	private string function _getVipsVersion() {
		var version = _exec( "vips", "--vips-version" );
		    version = listFirst( version, "-" );
		    version = listLast( version, " " );

		return version;
	}

	private numeric function _compareVersions( required string versionA, required string versionB ) {
		if ( versionA == versionB ) {
			return 0;
		}

		var a = ListToArray( versionA, "." );
		var b = ListToArray( versionB, "." );

		for( var i=1; i <= a.len(); i++ ) {
			if ( b.len() < i ) {
				return 1;
			}
			if ( a[i] > b[i] ) {
				return 1;
			}
			if ( a[i] < b[i] ) {
				return -1;
			}
		}

		return -1;
	}

// GETTERS AND SETTERS
	private string function _getBinDir() {
		return _binDir;
	}
	private void function _setBinDir( required string binDir ) {
		_binDir = arguments.binDir;
		_binDir = Replace( _binDir, "\", "/", "all" );
		_binDir = ReReplace( _binDir, "([^/])$", "\1/" );
	}

	private numeric function _getTimeout() {
		return _timeout;
	}
	private void function _setTimeout( required numeric timeout ) {
		_timeout = arguments.timeout;
	}

	private any function _getSvgToPngService() {
	    return _svgToPngService;
	}
	private void function _setSvgToPngService( required any svgToPngService ) {
	    _svgToPngService = arguments.svgToPngService;
	}

	private boolean function _getEnabled() {
	    return _enabled;
	}
	private void function _setEnabled( required boolean enabled ) {
	    _enabled = arguments.enabled;
	}
}