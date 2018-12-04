/**
 * @singleton      true
 * @presideservice true
 * @autodoc        true
 *
 * Service that deals with rendering Sticker includes at runtime in cached pages
 */
component {

// CONSTRUCTOR
	public any function init() {
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
		var dsPattern        = "<!--ds:\(type=(js|css),group=([a-zA-Z0-9_-]+)\)\((.+?)\):ds-->";
		var processed        = arguments.content;
		var cb               = $getColdbox();
		var event            = cb.getRequestContext();
		var patternFound     = false;
		var match            = "";
		var wholeMatch       = "";
		var type             = "";
		var group            = "";
		var stickerData      = "";
		var include          = "";
		var key              = "";
		var adhocArgs        = {};
		var renderedIncludes = "";

		do {
			match        = ReFind( dsPattern, processed, 1, true );
			patternFound = ( match.pos[ 1 ] ?: 0 ) > 0;

			if ( patternFound ) {
				wholeMatch  = Mid( processed, match.pos[ 1 ], match.len[ 1 ] );

				type        = Mid( processed, match.pos[ 2 ], match.len[ 2 ] );
				group       = Mid( processed, match.pos[ 3 ], match.len[ 3 ] );
				stickerData = Mid( processed, match.pos[ 4 ], match.len[ 4 ] );

				stickerData = deserializeJSON( stickerData );

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

				renderedIncludes = event.renderIncludes( type=type, group=group, delayed=false );
				processed        = Replace( processed, wholeMatch, renderedIncludes ?: "", "all" );
			}
		} while( patternFound )

		return processed;
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

}