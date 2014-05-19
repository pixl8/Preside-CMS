component extends="preside.system.base.Service" output=false {

// CONSTRUCTOR
	public any function init( required any assetManagerService, required any coldbox ) output=false {
		super.init( argumentCollection=arguments );

		_setAssetManagerService( arguments.assetManagerService );
		_setColdbox( arguments.coldbox );

		return this;
	}

// PUBLIC API METHODS
	public string function renderAsset( required string assetId, string context="default", struct args={} ) output=false {
		var asset = _getAssetManagerService().getAsset( arguments.assetId );

		if ( asset.recordCount ){
			for( var a in asset ) { asset = a; } // quick query row to struct

			StructAppend( asset, arguments.args, false );

			return _getColdbox().renderViewlet(
				  event = _getViewletForAssetType( asset.asset_type, arguments.context )
				, args  = asset
			);
		}

		return "";
	}

	public string function renderEmbeddedImages( required string richContent, string context="richeditor" ) output=false {
		var embeddedImage   = "";
		var renderedImage   = "";
		var renderedContent = arguments.richContent;

		do {
			embeddedImage = _findNextEmbeddedImage( renderedContent );

			if ( Len( Trim( embeddedImage.asset ?: "" ) ) ) {
				var viewletArgs = Duplicate( embeddedImage );

				viewletArgs.delete( "asset" );
				viewletArgs.delete( "placeholder" );

				renderedImage = renderAsset(
					  assetId = embeddedImage.asset
					, context = arguments.context
					, args    = viewletArgs
				);
			}

			if ( Len( Trim( embeddedImage.placeholder ?: "" ) ) ) {
				renderedContent = Replace( renderedContent, embeddedImage.placeholder, renderedImage, "all" );
			}

		} while ( StructCount( embeddedImage ) );

		return renderedContent;
	}

	public string function renderEmbeddedAttachments( required string richContent, string context="richeditor" ) output=false {
		var embeddedAttachment   = "";
		var renderedAttachment   = "";
		var renderedContent = arguments.richContent;

		do {
			embeddedAttachment = _findNextEmbeddedAttachment( renderedContent );

			if ( Len( Trim( embeddedAttachment.asset ?: "" ) ) ) {
				var viewletArgs = Duplicate( embeddedAttachment );

				viewletArgs.delete( "asset" );
				viewletArgs.delete( "placeholder" );

				renderedAttachment = renderAsset(
					  assetId = embeddedAttachment.asset
					, context = arguments.context
					, args    = viewletArgs
				);
			}

			if ( Len( Trim( embeddedAttachment.placeholder ?: "" ) ) ) {
				renderedContent = Replace( renderedContent, embeddedAttachment.placeholder, renderedAttachment, "all" );
			}

		} while ( StructCount( embeddedAttachment ) );

		return renderedContent;
	}


// PRIVATE HELPERS
	private string function _getViewletForAssetType( required string assetType, required string context ) output=false {
		var cb        = _getColdbox();
		var type      = _getAssetManagerService().getAssetType( name=arguments.assetType, throwOnMissing=true );
		var viewlet   = "";

		viewlet = "renderers.asset.#type.typeName#.#arguments.context#";
		if ( cb.viewletExists( viewlet ) ) {
			return viewlet;
		}

		viewlet = "renderers.asset.#type.groupName#.#arguments.context#";
		if ( cb.viewletExists( viewlet ) ) {
			return viewlet;
		}

		if ( arguments.context eq "default" ) {
			return "renderers.asset.default";
		}

		viewlet = "renderers.asset.#arguments.context#";
		if ( cb.viewletExists( viewlet ) ) {
			return viewlet;
		}

		return _getViewletForAssetType( arguments.assetType, "default" );
	}

	private struct function _findNextEmbeddedImage( required string richContent ) output=false {
		// The following regex is designed to match the following pattern that would be embedded in rich editor content:
		// {{image:{asset:"assetId",option:"value",option2:"value"}:image}}


		var regex  = "{{image:(.*?):image}}";
		var match  = ReFindNoCase( regex, arguments.richContent, 1, true );
		var img    = {};
		var config = "";

		if ( ArrayLen( match.len ) eq 2 and match.len[1] and match.len[2] ) {
			img.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );

			config = Mid( arguments.richContent, match.pos[2], match.len[2] );
			config = UrlDecode( config );

			try {
				config = DeserializeJson( config );
				StructAppend( img, config );
			} catch ( any e ) {}
		}

		return img;
	}

	private struct function _findNextEmbeddedAttachment( required string richContent ) output=false {
		// The following regex is designed to match the following pattern that would be embedded in rich editor content:
		// {{attachment:{asset:"assetId",option:"value",option2:"value"}:attachment}}


		var regex      = "{{attachment:(.*?):attachment}}";
		var match      = ReFindNoCase( regex, arguments.richContent, 1, true );
		var attachment = {};
		var config     = "";

		if ( ArrayLen( match.len ) eq 2 and match.len[1] and match.len[2] ) {
			attachment.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );

			config = Mid( arguments.richContent, match.pos[2], match.len[2] );
			config = UrlDecode( config );

			try {
				config = DeserializeJson( config );
				StructAppend( attachment, config );
			} catch ( any e ) {}
		}

		return attachment;
	}



// GETTERS AND SETTERS
	private any function _getAssetManagerService() output=false {
		return _assetManagerService;
	}
	private void function _setAssetManagerService( required any assetManagerService ) output=false {
		_assetManagerService = arguments.assetManagerService;
	}

	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}

}