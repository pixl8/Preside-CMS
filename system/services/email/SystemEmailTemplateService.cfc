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
		return StructKeyExists( _getConfiguredTemplates(), arguments.template );
	}

	/**
	 * Returns an array of configurable parameters for the given
	 * system email template. Each item in the array is a struct
	 * with the keys, `id`, `title`, `description` and `required`.
	 * The array is sorted by title.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose parameters you wish to get
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

	/**
	 * Returns a boolean defining whether email content for a system template should be
	 * saved or not.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose content save setting you wish to get
	 *
	 */
	public boolean function shouldSaveContentForTemplate( required string template ) {
		var templates = _getConfiguredTemplates();

		return templates[ arguments.template ].saveContent ?: true;
	}

	/**
	 * Returns a boolean defining whether email content for a system template should be
	 * saved or not.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose content save setting you wish to get
	 *
	 */
	public any function getSavedContentExpiry( required string template ) {
		var templates = _getConfiguredTemplates();

		return templates[ arguments.template ].contentExpiry ?: "";
	}

	/**
	 * Runs an email template's 'prepareParameters' handler action
	 * to prepare dynamic parameters for the email render.
	 *
	 * @autodoc             true
	 * @template.hint       ID of the template whose parameters are to be prepared
	 * @templateDetail.hint Struct with details of the template whose parameters are to be prepared
	 * @args.hint           A struct of args that have been passed to the email sending logic that will inform the building of this email
	 *
	 */
	public struct function prepareParameters(
		  required string template
		,          struct args           = {}
		,          struct templateDetail = {}
	) {
		var handlerAction = "email.template.#arguments.template#.prepareParameters";
		var prepArgs      = arguments.args.copy();

		prepArgs.templateDetail = arguments.templateDetail;

		if ( templateExists( arguments.template ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, eventArguments = prepArgs
				, private        = true
				, prePostExempt  = true
			);
		}

		return {};

	}


	/**
	 * Runs an email template's 'getPreviewParameters' handler action
	 * to prepare parameters for the email preview render.
	 *
	 * @autodoc       true
	 * @template.hint The template whose parameters are to be previewed
	 *
	 */
	public struct function getPreviewParameters( required string template ) {
		var handlerAction = "email.template.#arguments.template#.getPreviewParameters";

		if ( templateExists( arguments.template ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, private        = true
				, prePostExempt  = true
			);
		}

		return {};

	}

	/**
	 * Runs an email template's 'prepareAttachments' handler action
	 * to prepare dynamic attachments for the email send.
	 *
	 * @autodoc       true
	 * @template.hint The template whose attachments are to be prepared
	 * @args.hint     A struct of args that have been passed to the email sending logic that will inform the building of this email
	 *
	 */
	public array function prepareAttachments( required string template, struct args={} ) {
		var handlerAction = "email.template.#arguments.template#.prepareAttachments";

		if ( templateExists( arguments.template ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, eventArguments = arguments.args
				, private        = true
				, prePostExempt  = true
			);
		}

		return [];

	}

	/**
	 * Runs an email template's 'rebuildArgsForResend' handler action
	 * to rebuild arguments for resending an email.
	 *
	 * @autodoc       true
	 * @template.hint The template whose args are to be rebuilt
	 * @args.hint     A struct of args that have been passed to the email sending logic that will inform the building of this email
	 *
	 */
	public struct function rebuildArgsForResend(
		  required string template
		, required string logId
		, required struct originalArgs
	) {
		var handlerAction = "email.template.#arguments.template#.rebuildArgsForResend";

		if ( templateExists( arguments.template ) && $getColdbox().handlerExists( handlerAction ) ) {
			return $getColdbox().runEvent(
				  event          = handlerAction
				, eventArguments = { logId=arguments.logId }
				, private        = true
				, prePostExempt  = true
			);
		}

		return arguments.originalArgs;
	}

	/**
	 * Returns the default layout for a given template, read from the global
	 * email template configuration set in Config.cfc.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose default layout you wish to get
	 */
	public string function getDefaultLayout( required string template ) {
		var templates = _getConfiguredTemplates();

		return templates[ arguments.template ].layout ?: "default";
	}

	/**
	 * Returns the default subject for a given template, derived from its 'defaultSubject'
	 * viewlet.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose default subject you wish to get
	 */
	public string function getDefaultSubject( required string template ) {
		var viewlet = "email.template.#arguments.template#.defaultSubject";

		if ( templateExists( arguments.template ) && $getColdbox().viewletExists( viewlet ) ) {
			return $renderViewlet( viewlet );
		}

		return arguments.template;
	}

	/**
	 * Returns the default html body for a given template, derived from its 'defaultHtmlBody'
	 * viewlet.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose default html body you wish to get
	 */
	public string function getDefaultHtmlBody( required string template ) {
		var viewlet = "email.template.#arguments.template#.defaultHtmlBody";

		if ( templateExists( arguments.template ) && $getColdbox().viewletExists( viewlet ) ) {
			return $renderViewlet( viewlet );
		}

		return "";
	}


	/**
	 * Returns the default text body for a given template, derived from its 'defaultTextBody'
	 * viewlet.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose default text body you wish to get
	 */
	public string function getDefaultTextBody( required string template ) {
		var viewlet = "email.template.#arguments.template#.defaultTextBody";

		if ( templateExists( arguments.template ) && $getColdbox().viewletExists( viewlet ) ) {
			return $renderViewlet( viewlet );
		}

		return "";
	}


	/**
	 * Returns the recipient type for a given template, read from the global
	 * email template configuration set in Config.cfc.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose recipient type you wish to get
	 */
	public string function getRecipientType( required string template ) {
		var templates = _getConfiguredTemplates();

		return templates[ arguments.template ].recipientType ?: "anonymous";
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredTemplates() {
		return _configuredTemplates;
	}
	private void function _setConfiguredTemplates( required struct configuredTemplates ) {
		_configuredTemplates = {};
		for( var templateId in configuredTemplates ) {
			var feature = Trim( configuredTemplates[ templateId ].feature ?: "" );

			if ( !feature.len() || $isFeatureEnabled( feature ) ) {
				_configuredTemplates[ templateId ] = configuredTemplates[ templateId ];
			}
		}
	}

}