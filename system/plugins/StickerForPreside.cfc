component extends="coldbox.system.Plugin" output="false" singleton="true" {

	public any function init( controller ) output=false {
		super.init( arguments.controller );

		setpluginName("Sticker plugin for PresideCMS");
		setpluginVersion("1.0");
		setpluginDescription("Proxy to the Sticker API to be found here: https://github.com/pixl8/sticker");
		setPluginAuthor("Pixl8 Interactive");
		setPluginAuthorURL("www.pixl8.co.uk");

		_initSticker();

		return this;
	}

	public any function addBundle()      output=false { return _getSticker().addBundle     ( argumentCollection=arguments ); }
	public any function load()           output=false { return _getSticker().load          ( argumentCollection=arguments ); }
	public any function ready()          output=false { return _getSticker().ready         ( argumentCollection=arguments ); }
	public any function getAssetUrl()    output=false { return _getSticker().getAssetUrl   ( argumentCollection=arguments ); }
	public any function include()        output=false { return _getSticker().include       ( argumentCollection=arguments ); }
	public any function includeData()    output=false { return _getSticker().includeData   ( argumentCollection=arguments ); }
	public any function renderIncludes() output=false { return _getSticker().renderIncludes( argumentCollection=arguments ); }

// PRIVATE HELPERS
	private void function _initSticker() output=false {
		var sticker           = new sticker.Sticker();
		var settings          = super.getController().getSettingStructure();
		var sysAssetsPath     = "/preside/system/assets/"
		var extensionsRootUrl = "/preside/system/assets/extension/";
		var siteAssetsPath    = settings.static.siteAssetsPath ?: "/assets";
		var siteAssetsUrl     = settings.static.siteAssetsUrl  ?: "/assets";
		var rootURl           = ( settings.static.rootUrl ?: "" );

		sticker.addBundle( rootDirectory=sysAssetsPath , rootUrl=sysAssetsPath          , config=settings )
		       .addBundle( rootDirectory=siteAssetsPath, rootUrl=rootUrl & siteAssetsUrl, config=settings );

		for( var ext in settings.activeExtensions ) {
			if ( fileExists( ( ext.directory ?: "" ) & "/assets/StickerBundle.cfc" ) ) {
				sticker.addBundle( rootDirectory=( ext.directory ?: "" ) & "/assets", rootUrl=extensionsRootUrl & ListLast( ext.directory, "\/" ) & "/assets" );
			}
		}

		sticker.load();

		_setSticker( sticker );
	}

// GETTERS AND SETTERS
	private any function _getSticker() output=false {
		return _sticker;
	}
	private void function _setSticker( required any sticker ) output=false {
		_sticker = arguments.sticker;
	}

}