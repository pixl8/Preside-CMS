component singleton=true output=false {

// CONSTRUCTOR
	/**
	 * @assetManagerService.inject AssetManagerService
	 * @coldbox.inject             coldbox
	 *
	 */
	public any function init( required any assetManagerService, required any coldbox ) output=false {
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