/**
 * Service that deals with rendering Sticker includes at runtime in cached pages
 *
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 * @feature        delayedViewlets
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @dynamicFindAndReplaceService.inject dynamicFindAndReplaceService
	 *
	 */
	public any function init( required any dynamicFindAndReplaceService ) {
		_setDynamicFindAndReplaceService( arguments.dynamicFindAndReplaceService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Takes string content and injects dynamically rendered Sticker includes
	 * into locations that are marked up with delayed Sticker syntax
	 *
	 * @autodoc true
	 * @content The content to be parsed and injected with rendered Sticker includes
	 *
	 */
	public string function renderDelayedStickerIncludes( required string content ) {
		var dsPattern = "<!--ds:\(type=(js|css),group=([a-zA-Z0-9_-]+)\)\((.+?)\):ds-->";
		var event     = $getColdbox().getRequestContext();

		return _getDynamicFindAndReplaceService().dynamicFindAndReplace( source=arguments.content, regexPattern=dsPattern, recurse=false, processor=function( captureGroups ){
			var type        = arguments.captureGroups[ 2 ] ?: "";
			var group       = arguments.captureGroups[ 3 ] ?: "";
			var stickerData = arguments.captureGroups[ 4 ] ?: "";

			stickerData = DeserializeJSON( stickerData );

			for( include in stickerData.includes ?: [] ) {
				event.include( assetId=include, group=group );
			}
			for( key in stickerData.adhoc ?: {} ) {
				adhocArgs = {
					  url   = stickerData.adhoc[ key ].url
					, type  = stickerData.adhoc[ key ].type
					, media = stickerData.adhoc[ key ].media
				};
				adhocArgs.append( stickerData.adhoc[ key ].extraAttributes );
				event.includeUrl( argumentCollection=adhocArgs );
			}
			if ( !isEmpty( stickerData.data ?: {} ) ) {
				event.includeData( stickerData.data );
			}

			return event.renderIncludes( type=type, group=group, delayed=false );
		} );
	}

	/**
	 * Takes details of the Sticker group to be rendered
	 * and returns the special tag that can be parsed later in the request
	 *
	 * @autodoc       true
	 * @type          Sticker include type (css or js)
	 * @group         Sticker include group
	 * @memento       Sticker memento containing all sticker includes
	 */
	public string function renderDelayedStickerTag( required string type, string group="default", struct memento={} ) {
		var type        = arguments.type;
		var group       = arguments.group ?: "default";
		var stickerData = {
			  "includes" = structKeyArray( arguments.memento.includes[ group ] ?: {} )
			, "adhoc"    = arguments.memento.adhoc[ group ] ?: {}
		}
		if ( type == "js" ) {
			stickerData[ "data" ] = arguments.memento.data[ group ]  ?: {};
		};

		var tag = "<!--ds:(type=#type#,group=#group#)(#serializeJson( stickerData )#):ds-->";
		return tag;
	}

// GETTERS & SETTERS
	private any function _getDynamicFindAndReplaceService() {
	    return _dynamicFindAndReplaceService;
	}
	private void function _setDynamicFindAndReplaceService( required any dynamicFindAndReplaceService ) {
	    _dynamicFindAndReplaceService = arguments.dynamicFindAndReplaceService;
	}
}