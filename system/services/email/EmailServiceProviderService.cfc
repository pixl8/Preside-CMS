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
	 * Returns the configured/convention based send action for the
	 * given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider who's send action you wish to get
	 */
	public string function getProviderSendAction( required string provider ) {
		var rawProviders = _getConfiguredProviders();

		return rawProviders[ arguments.provider ].sendAction ?: ( "email.serviceProvider." & arguments.provider & ".send" );
	}


	/**
	 * Returns the configured/convention based validate settings action for the
	 * given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider who's validate settings action you wish to get
	 */
	public string function getProviderValidateSettingsAction( required string provider ) {
		var rawProviders = _getConfiguredProviders();

		return rawProviders[ arguments.provider ].validateSettingsAction ?: ( "email.serviceProvider." & arguments.provider & ".validateSettings" );
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

	/**
	 * Returns configured settings structure for the given provider
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider who's settings you wish to get
	 */
	public struct function getProviderSettings( required string provider ) {
		var categoryName = _getProviderSettingsCategory( arguments.provider );

		return $getPresideCategorySettings( categoryName );
	}

	/**
	 * Sends an email through the given provider's send action.
	 * Returns true to indicate that the email was sent successfully, false
	 * otherwise.
	 *
	 * @autodoc true
	 * @provider.hint ID of the provider through which to send the email
	 * @sendArgs.hint Structure of arguments to send to the provider's send handler action
	 */
	public boolean function sendWithProvider( required string provider, required struct sendArgs ) {
		var sendAction = getProviderSendAction( arguments.provider );
		var settings   = getProviderSettings( arguments.provider );

		if ( !$getColdbox().handlerExists( sendAction ) ) {
			throw(
				  type    = "preside.emailservice.provider.missing.send.action"
				, message = "The email service provider, [#arguments.provider#], has not implemented a send action handler. Missing handler: [#sendAction#]."
			);
		}

		try {
			var result = $getColdbox().runEvent(
				  event          = sendAction
				, eventArguments = { sendArgs=arguments.sendArgs, settings=settings }
				, private        = true
				, prePostExempt  = true
			);

			if ( IsBoolean( result ) ) {
				return result;
			}

			throw(
				  type    = "preside.emailservice.provider.invalid.send.action.return.value"
				, message = "The email service provider send action, [#sendAction#], for the provider, [#arguments.provider#], did not return a boolean value to indicate success/failure of email sending."
				, detail  = "The system has return false to indicate a failure and has logged this error silently as a warning."
			);

		} catch ( any e ) {
			$raiseError( e );
			return false;
		}
	}

	/**
	 * Validates the provided settings. Returns a [[validation-framework]] validationResult
	 * object with any validation errors.
	 *
	 * @autodoc true
	 * @provider.hint         Provider who's settings we are to validate
	 * @settings.hint         Struct of settings to validate
	 * @validationResult.hint Pre-initialized validationResult object - any validation results will be added to this object and returned
	 *
	 */
	public any function validateSettings(
		  required string provider
		, required struct settings
		,          any    validationResult = $newValidationResult()
	) {
		var validateAction = getProviderValidateSettingsAction( provider );

		if ( $getColdbox().handlerExists( validateAction ) ) {
			$getColdbox().runEvent(
				  event          = validateAction
				, eventArguments = { settings=arguments.settings, validationResult=arguments.validationResult }
				, private        = true
				, prePostExempt  = true
			);
		}

		return arguments.validationResult;
	}

	/**
	 * Saves the settings for a particular service provider and optional site
	 *
	 * @autodoc       true
	 * @provider.hint ID of the provider who's settings you want to save
	 * @settings.hint Structure of settings to save
	 * @site.hint     Optional ID of preside site to save the settings against
	 */
	public void function saveSettings(
		  required string provider
		, required struct settings
		,          string site = ""
	) {
		var settingsCategory = _getProviderSettingsCategory( arguments.provider );
		var configService    = $getSystemConfigurationService();

		for( var key in arguments.settings ) {
			configService.saveSetting(
				  category = settingsCategory
				, setting  = key
				, value    = arguments.settings[ key ]
				, siteId   = arguments.site
			);
		}

		return;
	}

// PRIVATE HELPERS
	private string function _getProviderSettingsCategory( required string provider ) {
		return "email.serviceProvider.#provider#";
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required struct configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}
}