component output="false" displayname="ImageMagick"  {

	public any function init(
		 required string  path
		, 		  numeric timeout = 30
	) {
		_setExecutablePath( arguments.path );
		_setTimeout( arguments.timeout );
		return this;
	}

	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
		,          struct  assetProperty       =  {}
	) output=false {
		var image              = "";
		var interpolation      = arguments.quality
		var targetAspectRatio  = 0;
		var currentImageInfo   = {};
		var currentAspectRatio = 0;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.resize.notAnImage" );
		}

		if( !structIsEmpty( arguments.assetProperty ) ){
			currentImageInfo.height = arguments.assetProperty.height ?: 0;
			currentImageInfo.width  = arguments.assetProperty.width  ?: 0;
		}else{
			currentImageInfo = ImageInfo( image );
		}

		var imageMagickFile = "";

		if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		} else {

			imageMagickFile   = imageMagickResize(
				  sourceFile      = assetProperty.sourceFile
				, destinationFile = assetProperty.destinationFile
				, width           = arguments.width
				, height          = arguments.height
				, expand          = maintainAspectRatio
				, crop            = maintainAspectRatio
			);
		}

		image = FileReadBinary( imageMagickFile );

		return ImageGetBlob( image );
	}

	public binary function pdfPreview(
		  required binary asset
		,          string scale
		,          string resolution
		,          string format
		,          string pages          = 0
		,          string transparent
		,          struct assetProperty =  {}
	) {
		var imagePrefix = CreateUUId();
		var tmpFilePath = GetTempDirectory() & "/" & imagePrefix & ".jpg";
		var allowedArgs = [ "scale", "resolution", "format", "pages", "transparent", "maxscale", "maxlength", "maxbreadth" ];

		assetProperty.destinationFile = replaceNoCase(assetProperty.destinationFile, ".pdf", ".jpg");
		execArgs.process     = "convert";
		execArgs.destination = GetTempDirectory();

		execArgs.args = '-density 100 -colorspace rgb "#arguments.assetProperty.sourceFile#[1]" "#tmpFilePath#"';

		for( var arg in allowedArgs ) {
			if ( StructKeyExists( arguments, arg ) ) {
				execArgs[ arg ] = arguments[ arg ];
			}
		}

		execute(argumentCollection=execArgs);

		return FileReadBinary( tmpFilePath );
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality = "highPerformance"
		,          struct  assetProperty       =  {}
	) output=false {

		var image         = "";
		var imageInfo     = "";
		var interpolation = arguments.quality;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		if( !structIsEmpty( arguments.assetProperty ) ){
			currentImageInfo.height = arguments.assetProperty.height ?: 0;
			currentImageInfo.width  = arguments.assetProperty.width  ?: 0;
		} else {
			currentImageInfo = ImageInfo( image );
		}

		var imageMagickFile = "";

		if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		} else {
			var imageMagickFile   = imageMagickResize(
				  sourceFile      = assetProperty.sourceFile
				, destinationFile = assetProperty.destinationFile
				, width           = arguments.width
				, height          = arguments.height
				, expand          = true
				, crop            = false
			);
		}
		image = FileReadBinary( imageMagickFile );

		return ImageGetBlob( image );
	}

	public string function imageMagickResize(
		  required string  sourceFile
		, required string  destinationFile
		, required numeric width
		, required numeric height
		,          boolean expand    = false
		,          boolean crop      = false
		,          string  gravity   = 'center'
	) {

		var execArgs  = {
			  process = "convert"
			, args    = '"#arguments.sourceFile#" -resize #arguments.width#x#arguments.height#'
        };

    	if ( arguments.expand ) {
    		if ( arguments.crop ) {
    			execArgs.args &= "^";
    		}
    		execArgs.args &= " -gravity #arguments.gravity# -extent #arguments.width#x#arguments.height#";
    	}

    	execArgs.args &= " " & arguments.destinationFile;

       	execute( argumentCollection = execArgs );

    	return arguments.destinationFile;

	}

	private string function execute(
		  required string process
		, required string args
	) {
		var result = "";
		cfexecute( name      = "#_getExecutablePath()#\#arguments.process#.exe"
				  ,arguments = "#arguments.args#"
				  ,timeout   = "#_getTimeout()#"
				  ,variable  = "result");
		return result;
	}

	private string function _getExecutablePath() {
		return _executablePath;
	}

	private void function _setExecutablePath(
		required string executablePath
	) {
		_executablePath = arguments.executablePath;
	}

	private numeric function _getTimeout() {
		return _timeout;
	}

	private void function _setTimeout(
		required string timeout
	) {
		_timeout = arguments.timeout;
	}
}