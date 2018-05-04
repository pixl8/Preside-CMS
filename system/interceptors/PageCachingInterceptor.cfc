component extends="coldbox.system.Interceptor" {

	property name="cache"                         inject="cachebox:PresidePageCache";
	property name="delayedViewletRendererService" inject="delayedInjector:delayedViewletRendererService";
	property name="delayedStickerRendererService" inject="delayedInjector:delayedStickerRendererService";
	property name="loginService"                  inject="delayedInjector:websiteLoginService";

// PUBLIC
	public void function configure() {}

	public void function onRequestCapture( event ) {
		if ( event.cachePage() ) {
			var cacheKey = _getCacheKey( event );
			var cached   = cache.get( cacheKey );

			if ( !IsNull( local.cached ) ) {
				event.restoreCachedData( cached.data ?: {} );
				event.checkPageAccess();
				var viewletsRendered = delayedViewletRendererService.renderDelayedViewlets( cached.body ?: "" );
				content reset=true;
				echo( delayedStickerRendererService.renderDelayedStickerIncludes( viewletsRendered ) );
				abort;
			}
		}
	}

	public void function preRender( event, interceptData ) {
		var content = interceptData.renderedContent ?: "";

		if ( event.cachePage() ) {
			cache.set(
				  objectKey = _getCacheKey( event )
				, object    = { body=content, data=event.getCacheableRequestData() }
				, timeout   = event.getPageCacheTimeout()
			);
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

		return "pagecache" & event.getCurrentUrl() & ( isLoggedIn ? "$loggedin" : "" );
	}

	private void function _clearCaches( event, interceptData ) {
		if ( ( interceptData.objectName ?: "" ) == "page" ) {
			cache.clearAll();
		}
	}
}