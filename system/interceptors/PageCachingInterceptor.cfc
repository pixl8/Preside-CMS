component extends="coldbox.system.Interceptor" {

	property name="cache"                         inject="cachebox:PresidePageCache";
	property name="delayedViewletRendererService" inject="delayedInjector:delayedViewletRendererService";
	property name="delayedStickerRendererService" inject="delayedInjector:delayedStickerRendererService";
	property name="loginService"                  inject="delayedInjector:websiteLoginService";
	property name="websiteUserActionService"      inject="delayedInjector:websiteUserActionService";

// PUBLIC
	public void function configure() {}

	public void function onRequestCapture( event ) {
		if ( event.cachePage() ) {
			var cacheKey = _getCacheKey( event );
			var cached   = cache.get( cacheKey );

			if ( !IsNull( local.cached ) ) {
				event.restoreCachedData( cached.data ?: {} );
				event.checkPageAccess();
				event.setXFrameOptionsHeader();
				event.setHTTPHeader( name="X-Cache", value="HIT" );
				var viewletsRendered = delayedViewletRendererService.renderDelayedViewlets( cached.body ?: "" );
				var contentType      = cached.contentType ?: "";
				var pageId           = event.getCurrentPageId();

				if ( Len( Trim( pageId ) ) ) {
					websiteUserActionService.recordAction(
						  action     = "pagevisit"
						, type       = "request"
						, identifier = pageId
						, userId     = getLoggedInUserId()
					);
				}

				content reset=true;
				if ( len( contentType ) ) {
					content type=contentType;
				}
				echo( delayedStickerRendererService.renderDelayedStickerIncludes( viewletsRendered ) );
				abort;
			}
		}

		event.setNonCacheableRequestData();
	}

	public void function preRender( event, interceptData ) {
		var content     = interceptData.renderedContent ?: "";
		var contentType = interceptData.contentType     ?: "";

		if ( event.cachePage() ) {
			cache.set(
				  objectKey = _getCacheKey( event )
				, object    = {
					  body        = content
					, data        = event.getCacheableRequestData()
					, contentType = contentType
				  }
				, timeout   = event.getPageCacheTimeout()
			);
			event.setHTTPHeader( name="X-Cache", value="MISS" );
		}

		var viewletsRendered          = delayedViewletRendererService.renderDelayedViewlets( content );
		interceptData.renderedContent = delayedStickerRendererService.renderDelayedStickerIncludes( viewletsRendered );
	}

	public void function postUpdateObjectData( event, interceptData ) {
		_clearCaches( argumentCollection=arguments );
	}

	public void function postInsertObjectData( event, interceptData ) {
		_clearCaches( argumentCollection=arguments );
	}

	public void function postDeleteObjectData( event, interceptData ) {
		_clearCaches( argumentCollection=arguments );
	}


// PRIVATE HELPERS
	private string function _getCacheKey( event ) {
		var isLoggedIn = loginService.get().isLoggedIn();
		var fullUrl    = event.getBaseUrl() & event.getCurrentUrl();
		var isAjax     = event.isAjax();

		return "pagecache" & fullUrl & ( isLoggedIn ? "$loggedin" : "" ) & ( isAjax ? "$ajax" : "" );
	}

	private void function _clearCaches( event, interceptData ) {
		if ( ( interceptData.objectName ?: "" ) == "page" ) {
			cache.clearAll();
		}
	}
}