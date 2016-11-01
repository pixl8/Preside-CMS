/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 *
 */
component {

	/**
	 * @configuredTemplates.inject coldbox:setting:email.templates
	 */
	public any function init( required struct configuredTemplates ) {
		_setConfiguredTemplates( arguments.configuredTemplates );

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of templates describing the application's
	 * available system email templates. Each struct contains `id`, `title`
	 * and `description` keys. Templates are ordered by title (ascending).
	 *
	 * @autodoc
	 *
	 */
	public array function listTemplates() {
		var templateIds = _getConfiguredTemplates().keyArray();
		var templates   = [];

		for( var templateId in templateIds ) {
			templates.append({
				  id          = templateId
				, title       = $translateResource( uri="email.template.#templateId#:title"      , defaultValue=templateId )
				, description = $translateResource( uri="email.template.#templateId#:description", defaultValue=""         )
			});
		}

		templates.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );


		return templates;
	}

	/**
	 * Returns whether or not the provided template
	 * is configured in the system.
	 *
	 * @autodoc       true
	 * @template.hint The ID of the template to check
	 */
	public boolean function templateExists( required string template ) {
		return _getConfiguredTemplates().keyExists( arguments.template );
	}

	/**
	 * Returns an array of configurable parameters for the given
	 * system email template. Each item in the array is a struct
	 * with the keys, `id`, `title`, `description` and `required`.
	 * The array is sorted by title.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template who's parameters you wish to get
	 *
	 */
	public array function listTemplateParameters( required string template ) {
		var params         = [];
		var templates      = _getConfiguredTemplates();
		var templateParams = templates[ arguments.template ].parameters ?: [];

		for( var param in templateParams ) {
			var translatedParam = {};

			if ( IsSimpleValue( param ) ) {
				translatedParam = {
					  id = param
					, required = false
				};
			} else {
				translatedParam = {
					  id       = param.id ?: CreateUUId()
					, required = IsBoolean( param.required ?: "" ) && param.required
				};
			}

			translatedParam.title       = $translateResource( uri="email.template.#arguments.template#:param.#translatedParam.id#.title"      , defaultValue=translatedParam.id );
			translatedParam.description = $translateResource( uri="email.template.#arguments.template#:param.#translatedParam.id#.description", defaultValue="" );

			params.append( translatedParam );
		}

		params.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return params;
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredTemplates() {
		return _configuredTemplates;
	}
	private void function _setConfiguredTemplates( required struct configuredTemplates ) {
		_configuredTemplates = arguments.configuredTemplates;
	}

}