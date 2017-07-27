component extends="coldbox.system.Interceptor" {

	property name="cache"                         inject="cachebox:template";
	property name="delayedViewletRendererService" inject="delayedInjector:delayedViewletRendererService";
	property name="loginService"                  inject="delayedInjector:websiteLoginService";

// PUBLIC
	public void function configure() {}

	public void function onRequestCapture( event ) {
		if ( event.cachePage() ) {
			var cacheKey = _getCacheKey( event );
			var cached   = cache.get( cacheKey );

			if ( !IsNull( cached ) ) {
				event.restoreCachedData( cached.data ?: {} );
				content reset=true;
				echo( delayedViewletRendererService.renderDelayedViewlets( cached.body ?: "" ) );
				abort;
			}
		}
	}

	public void function preRender( event, interceptData ) {
		var content = interceptData.renderedContent ?: "";

		if ( event.cachePage() ) {
			var cacheKey = _getCacheKey( event );
			cache.set( cacheKey, {
				  body = content
				, data = event.getCacheableRequestData()
			} )
		}

		interceptData.renderedContent = delayedViewletRendererService.renderDelayedViewlets( content );
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