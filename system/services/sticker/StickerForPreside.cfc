/**
 * @presideService true
 * @singleton      true
 *
 */
component {

	/**
	 * @delayedStickerRendererService.inject delayedStickerRendererService
	 *
	 */
	public any function init( required any delayedStickerRendererService ) {
		_setDelayedStickerRendererService( arguments.delayedStickerRendererService );
		_initSticker();

		return this;
	}

	public any function addBundle()      { return _getSticker().addBundle     ( argumentCollection=arguments ); }
	public any function load()           { return _getSticker().load          ( argumentCollection=arguments ); }
	public any function ready()          { return _getSticker().ready         ( argumentCollection=arguments ); }
	public any function getAssetUrl()    { return _getSticker().getAssetUrl   ( argumentCollection=arguments ); }
	public any function include()        { return _getSticker().include       ( argumentCollection=arguments ); }
	public any function includeData()    { return _getSticker().includeData   ( argumentCollection=arguments ); }
	public any function includeUrl()     { return _getSticker().includeUrl    ( argumentCollection=arguments ); }

	public any function renderIncludes( boolean delayed=$isFeatureEnabled( "fullpageCaching" ) ) {
		if ( delayed ) {
			return _getDelayedStickerRendererService().renderDelayedStickerTag( argumentCollection=arguments, memento=_getSticker().getMemento() );
		} else {
			return _getSticker().renderIncludes( argumentCollection=arguments );
		}
	}

// PRIVATE HELPERS
	private void function _initSticker() {
		var sticker           = new sticker.Sticker();
		var settings          = $getColdbox().getSettingStructure();
		var sysAssetsPath     = "/preside/system/assets/"
		var extensionsRootUrl = "/preside/system/assets/extension/";
		var siteAssetsPath    = settings.static.siteAssetsPath ?: "/assets";
		var siteAssetsUrl     = settings.static.siteAssetsUrl  ?: "/assets";
		var rootURl           = ( settings.static.rootUrl ?: "" );

		sticker.addBundle( rootDirectory=sysAssetsPath , rootUrl=sysAssetsPath, config=settings );

		for( var ext in settings.activeExtensions ) {
			var stickerDirectory  = ( ext.directory ?: "" ) & "/assets";
			var stickerBundleFile = stickerDirectory & "/StickerBundle.cfc";

			if ( FileExists( stickerBundleFile ) ) {
				sticker.addBundle( rootDirectory=stickerDirectory, rootUrl=extensionsRootUrl & ListLast( ext.directory, "\/" ) & "/assets" );
			}
		}

		sticker.addBundle( rootDirectory=siteAssetsPath, rootUrl=rootUrl & siteAssetsUrl, config=settings );

		sticker.load();

		_setSticker( sticker );
	}

// GETTERS AND SETTERS
	private any function _getDelayedStickerRendererService() {
		return _delayedStickerRendererService;
	}
	private void function _setDelayedStickerRendererService( required any delayedStickerRendererService ) {
		_delayedStickerRendererService = arguments.delayedStickerRendererService;
	}

	private any function _getSticker() {
		return _sticker;
	}
	private void function _setSticker( required any sticker ) {
		_sticker = arguments.sticker;
	}

}