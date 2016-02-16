component output="false" displayname="ImageMagick"  {

	public any function init(
		 required string  path
		, 		  string timeout = 30
	) {
		_setExecutablePath( arguments.path );
		_setTimeout( arguments.timeout );
		return this;
	}

	public any function resize(
		  required binary  asset
		, 		   string  width       = ""
		,		   string  height 	   = ""
		,		   boolean bExtent 	   = false
		,		   boolean bExtentFull = false
		,		   string  sGravity    = "center"
	) {
		var sourcePath = expandPath( '/uploads/assets/temp/' ) ;
		var destPath   = expandPath( '/uploads/assets/temp/dest/' );

		imagewrite(arguments.asset, sourcePath);
		var execArgs  = {
			  process = "convert"
			, args    = '#sourcePath#'
        };

        if ( arguments.bExtent ) {
        	if ( bExtentFull ) {
        		execArgs.args &= "^";
        	}
        	execArgs.args &= " -gravity #arguments.sGravity# -extent #arguments.width#x#arguments.height#";
        }

       	execArgs.args &= " " & destPath;

       	execute( argumentCollection = execArgs );

       	image = FileReadBinary( destPath );

		return ImageGetBlob( image );

	}


	public void function convertPDFtoImage(
		  required string pdfSource
		, required string destination
		, 		   string page        = "0"
		, 		   string format      = "jpg"
		,		   string resolution  = "200"
		,		   string imagePrefix = ""

	) {
		var execArgs=StructNew();
		if( !Len( Trim( arguments.imagePrefix ) ) ){
			var pdfFileName = ListGetAt( arguments.pdfSource,ListLen( arguments.pdfSource,"\" ),"\" );
			arguments.imagePrefix = listDeleteAt( pdfFileName, ListLen( pdfFileName,"." ), "." );
		}

		execArgs.process = "convert"
		execArgs.timeout = "20"
		if( arguments.format == 'jpg' ){
			execArgs.args = "-density #arguments.resolution# -background white -alpha remove -quality 100 #arguments.pdfSource#[#arguments.page#] #arguments.destination & arguments.imagePrefix#.#arguments.format#";
		}else{
			execArgs.args = "-density #arguments.resolution# -quality 100 #arguments.pdfSource#[#arguments.page#] #arguments.destination & arguments.imagePrefix#.#arguments.format#";
		}
		execute(argumentCollection=execArgs);
	}


	public boolean function validate(
		required string filePath
	) {
		var channelAndDimensions = Trim( LCase( execute(
				  process = "identify"
				, args    = '-format "%[channels] %wx%h" "#arguments.filePath#"' )
			) );
			var dimensions = "";

			if( not Len( Trim( channelAndDimensions ) ) ) {
				return false;
			}

			if ( ListLen( channelAndDimensions, " " ) gt 1 ) {
				if ( ListFirst( channelAndDimensions, " " ) contains "cmyk" ) {
					execute( process = "convert", args = '"#arguments.filePath#" -profile #ExpandPath("/pcmscore/api/assetmanager/color-profile/GenericCMYK.icm")# -profile #ExpandPath("/pcmscore/api/assetmanager/color-profile/sRGB_v4_ICC_preference.icc")# "#arguments.filePath#"' );
				}

				dimensions = ListRest( channelAndDimensions, " " );
			} else {
				dimensions = channelAndDimensions;
			}

			return ListLen( dimensions, "x" ) eq 2
			   and Val( ListFirst( dimensions, "x" ) )
			   and Val( ListLast ( dimensions, "x" ) );
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
			imageInfo.height = arguments.assetProperty.height ?: 0;
			imageInfo.width  = arguments.assetProperty.width  ?: 0;
		}else{
			imageInfo = ImageInfo( image );
		}

		var imageMagickFile   = imageMagickResize(
			  sourceFile      = assetProperty.sourceFile
			, destinationFile = assetProperty.destinationFile
			, width           = arguments.width
			, height          = arguments.height
			, expand          = true
			, crop            = false
		);

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

		var execArgs = '"#arguments.sourceFile#" -resize #arguments.width#x#arguments.height#';

    	if ( arguments.expand ) {
    		if ( arguments.crop ) {
    			execArgs &= "^";
    		}
    		execArgs &= " -gravity #arguments.gravity# -extent #arguments.width#x#arguments.height#";
    	}

    	execArgs &= " " & arguments.destinationFile;

    	cfexecute( name = "convert", arguments = execArgs );

    	return arguments.destinationFile;

	}

	private private function execute(
		  required string process
		, required string args
	) {

		var result = "";
		cfexecute( name      = "#_getExecutablePath()##arguments.process#"
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