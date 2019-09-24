/**
 * Provides logic for rendering assets. See [[assetmanager]] for more detailed documentation on working with assets.
 *
 * @autodoc
 * @singleton
 *
 */
component displayname="Asset Renderer Service" {

// CONSTRUCTOR
	/**
	 * @assetManagerService.inject AssetManagerService
	 * @coldbox.inject             coldbox
	 * @renderedAssetCache.inject  cachebox:renderedAssetCache
	 *
	 */
	public any function init( required any assetManagerService, required any coldbox, required any renderedAssetCache ) {
		_setAssetManagerService( arguments.assetManagerService );
		_setRenderedAssetCache( arguments.renderedAssetCache );
		_setColdbox( arguments.coldbox );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Renders a given asset in an optional context. See [[assetmanager]] for more detailed documentation on working with assets.
	 *
	 * @autodoc
	 * @assetId.hint    The ID of the asset record to render
	 * @context.hint    The context in which the asset should be rendered. This will inform the choice of viewlet used to render the asset.
	 * @args.hint       Arbitrary args struct to be passed to the viewlet that will render this asset
	 * @args.docdefault {}
	 */
	public string function renderAsset( required string assetId, string context="default", struct args={} ) {
		var cacheKey  = "asset-#arguments.assetId#-#arguments.context#-#Serialize( args )#";
		var fromCache = _getRenderedAssetCache().get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var asset = _getAssetManagerService().getAsset( arguments.assetId );

		if ( asset.recordCount ){
			for( var a in asset ) { asset = a; } // quick query row to struct

			StructAppend( asset, arguments.args, false );

			var rendered = _getColdbox().renderViewlet(
				  event = _getViewletForAssetType( asset.asset_type, arguments.context )
				, args  = asset
			);

			_getRenderedAssetCache().set( cacheKey, rendered );

			return rendered;
		}

		_getRenderedAssetCache().set( cacheKey, "" );

		return "";
	}


// PRIVATE HELPERS
	private string function _getViewletForAssetType( required string assetType, required string context ) {
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
	private any function _getAssetManagerService() {
		return _assetManagerService;
	}
	private void function _setAssetManagerService( required any assetManagerService ) {
		_assetManagerService = arguments.assetManagerService;
	}

	private any function _getColdbox() {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) {
		_coldbox = arguments.coldbox;
	}

	private any function _getRenderedAssetCache() {
	    return _renderedAssetCache;
	}
	private void function _setRenderedAssetCache( required any renderedAssetCache ) {
	    _renderedAssetCache = arguments.renderedAssetCache;
	}

}