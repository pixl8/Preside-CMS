component output=false singleton=true {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API METHODS
	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
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

		currentImageInfo = ImageInfo( image );

		if ( !arguments.height ) {
			if ( currentImageInfo.width == arguments.width ) {
				return arguments.asset;
			}
			ImageScaleToFit( image, arguments.width, "", interpolation );
		} else if ( !arguments.width ) {
			if ( currentImageInfo.height == arguments.height ) {
				return arguments.asset;
			}
			ImageScaleToFit( image, "", arguments.height, interpolation );
		} else if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		} else {
			if ( maintainAspectRatio ) {
				currentAspectRatio = currentImageInfo.width / currentImageInfo.height;
				targetAspectRatio  = arguments.width / arguments.height;
			}

			if ( not maintainAspectRatio or targetAspectRatio eq currentAspectRatio ) {
				ImageResize( image, arguments.width, arguments.height, interpolation );
			} else {
				if ( currentAspectRatio gt targetAspectRatio ) {
					ImageScaleToFit( image, "", arguments.height, interpolation );
					var scaledImgInfo = ImageInfo( image );
					ImageCrop( image, Int( ( scaledImgInfo.width - arguments.width ) / 2 ), 0, arguments.width, arguments.height );
				} else {
					ImageScaleToFit( image, arguments.width, "", interpolation );
					var scaledImgInfo = ImageInfo( image );
					ImageCrop( image, 0, Int( ( scaledImgInfo.height - arguments.height ) / 2 ), arguments.width, arguments.height );
				}
			}
		}

		return ImageGetBlob( image );
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality = "highPerformance"
	) output=false {
		var image         = "";
		var imageInfo     = "";
		var interpolation = arguments.quality;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		imageInfo = ImageInfo( image );
		if ( imageInfo.width > arguments.width || imageInfo.height > arguments.height ) {
				ImageScaleToFit( image, arguments.width, arguments.height, interpolation );
		}

		return ImageGetBlob( image );
	}

	public binary function pdfPreview( required binary asset ) output=false {
		var imagePrefix = CreateUUId();
		var tmpFilePath = GetTempDirectory() & "/" & imagePrefix & "_page_" & arguments.page & ".jpg";
		var allowedArgs = [ "scale", "resolution", "format", "pages", "transparent", "maxscale", "maxlength", "maxbreadth" ];
		var pdfAttributes = {
			  action      = "thumbnail"
			, source      = asset
			, destination = GetTempDirectory()
			, imagePrefix = imagePrefix
		};

		for( var arg in allowedArgs ) {
			if ( StructKeyExists( arguments, arg ) ) {
				pdfAttributes[ arg ] = arguments[ arg ];
			}
		}

		pdf attributeCollection=pdfAttributes;

		return FileReadBinary( tmpFilePath );
	}

	public struct function getImageInformation( required binary asset ) output=false {
		try {
			return ImageInfo( ImageNew( arguments.asset ) );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		return {};
	}
}