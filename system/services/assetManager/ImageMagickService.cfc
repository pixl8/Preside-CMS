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

		var currentImageInfo   = {};
		var tmpFilePath        = getTempFile( GetTempDirectory(), "mgk" );

		FileWrite( tmpFilePath, arguments.asset );

		imageMagickResize(
			  sourceFile      = tmpFilePath
			, destinationFile = tmpFilePath
			, qualityArgs     = _cfToImQuality( arguments.quality )
			, width           = arguments.width
			, height          = arguments.height
			, expand          = maintainAspectRatio
			, crop            = maintainAspectRatio
		);

		var binary = FileReadBinary( tmpFilePath );

		FileDelete( tmpFilePath );

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

		var tmpFilePath       = GetTempFile( GetTempDirectory(), "mgk" );
		var shrinkToWidth     = arguments.width;
		var shrinkToHeight    = arguments.height;
		var widthChangeRatio  = currentImageInfo.width / shrinkToWidth;
		var heightChangeRatio = currentImageInfo.height / shrinkToHeight;

		FileWrite( tmpFilePath, arguments.asset );

		if ( widthChangeRatio > heightChangeRatio ) {
			shrinkToHeight = 0;
		} else {
			shrinkToWidth = 0;
		}

		imageMagickResize(
			  sourceFile      = tmpFilePath
			, destinationFile = tmpFilePath
			, qualityArgs      = _cfToImQuality( arguments.quality )
			, width           = shrinkToWidth
			, height          = shrinkToHeight
			, expand          = true
			, crop            = false
		);

		var binary = FileReadBinary( tmpFilePath );

		FileDelete( tmpFilePath );

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
		var result = "";
		var config = $getPresideCategorySettings( "asset-manager" );
		var binDir = Trim( config.imagemagick_path ?: "" );

		if ( Len( binDir ) ) {
			binDir = Replace( binDir, "\", "/", "all" );
			binDir = ReReplace( binDir, "([^/])$", "\1/" );
		}

		execute name      = binDir & arguments.command
				arguments = arguments.args
				timeout   = Val( config.imagemagick_timeout ?: 30 )
				variable  = "result";

		return result;
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
}