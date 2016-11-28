/**
 * Provides logic for dealing with email service providers. i.e. services
 * that allow sending of email (e.g. smtp, mailgun + other APIs, etc.).
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredProviders.inject coldbox:setting:email.serviceProviders
	 *
	 */
	public any function init( required struct configuredProviders ) {
		_setConfiguredProviders( arguments.configuredProviders );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of configured providers with translated
	 * titles, descriptions and icon classes. Providers are
	 * ordered by transated title.
	 *
	 * @autodoc true
	 */
	public array function listProviders() {
		var rawProviders      = _getConfiguredProviders();
		var providers         = [];
		var disabledProviders = $getPresideSetting( "email.serviceProviders", "disabledProviders" ).listToArray();

		for( var providerId in rawProviders ) {
			if ( !disabledProviders.findNoCase( providerId ) ) {
				var uriRoot = "email.serviceProvider.#providerId#:";
				providers.append( {
					  id          = providerId
					, title       = $translateResource( uri=uriRoot & "title"      , defaultValue=providerId )
					, description = $translateResource( uri=uriRoot & "description", defaultValue="" )
					, iconClass   = $translateResource( uri=uriRoot & "iconClass"  , defaultValue="" )
				} );
			}
		}

		providers.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return providers;
	}

	/**
	 * Returns the configured default provider.
	 *
	 * @autodoc true
	 */
	public string function getDefaultProvider() {
		var provider = $getPresideSetting( "email.serviceProviders", "defaultProvider" );

		if ( provider.len() ) {
			return provider;
		}

		var providers = listProviders();

		return providers[1].id ?: "";
	}

	/**
	 * Returns the configuration form name for
	 * the given provider.
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider who's config form name you wish to get
	 */
	public string function getProviderConfigFormName( required string provider ) {
		var rawProviders = _getConfiguredProviders();

		return rawProviders[ arguments.provider ].configForm ?: ( "email.serviceProvider." & arguments.provider );
	}

	/**
	 * Returns whether or not the given provider is enabled.
	 *
	 * @autodoc true
	 * @provider.hint ID of the provider who's enabled/disabled status you wish to check
	 */
	public boolean function isProviderEnabled( required string provider ) {
		var disabledProviders = $getPresideSetting( "email.serviceProviders", "disabledProviders" ).listToArray();

		if ( disabledProviders.findNoCase( arguments.provider ) ) {
			return false;
		}

		var configuredProviders = _getConfiguredProviders();

		return configuredProviders.keyExists( arguments.provider );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private struct function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required struct configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}
}