/**
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function renderProviderLoginPrompt(
		  required string  provider
		, required string  postLoginUrl
		, required numeric position
	) {
		var viewletEvent = "admin.loginProvider.#provider#.prompt";
		var coldbox      = $getColdbox();

		if ( coldbox.viewletExists( viewletEvent ) ) {
			return coldbox.renderViewlet( event=viewletEvent, args={
				  postLoginUrl = arguments.postLoginUrl
				, position     = arguments.position
			} );
		}

		throw( type="preside.admin.login.provider.not.found", message="The login provider, [#provider#], has not implemented a 'admin.loginProvider.#provider#.prompt' viewlet. All providers must provide this handler to be user accessible from the login prompt." );
	}

	public boolean function isProviderEnabled( required string provider ) {
		var providers = listProviders();

		return ArrayFindNoCase( providers, arguments.provider );
	}

	public array function listProviders() {
		var providers = $getColdbox().getSetting( "adminLoginProviders" );

		return IsArray( providers ) ? providers : [];
	}
}