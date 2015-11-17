component extends="coldbox.system.Interceptor" output=false {

	property name="urlRedirectsService" inject="delayedInjector:urlRedirectsService";

	public void function configure() output=false {
		super.configure( argumentCollection = arguments );
	}

	public void function onRequestCapture( event, interceptData ) output=false {
		var path    = event.getCurrentUrl( includeQueryString=true );
		var fullUrl = event.getBaseUrl() & path;

		urlRedirectsService.redirectOnMatch(
			  path    = path
			, fullUrl = fullUrl
		);
	}
}