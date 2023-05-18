/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 *
 */
component {
	property name="emailTemplateService" inject="delayedInjector:emailTemplateService";

	/**
	 * @configuredTemplates.inject  coldbox:setting:email.templates
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
		var allTemplates = _getConfiguredTemplates();
		var templateIds  = StructKeyArray( allTemplates );
		var templates    = [];

		for( var templateId in templateIds ) {
			ArrayAppend( templates, {
				  id          = templateId
				, group       = allTemplates[ templateId ].group ?: "unclassified"
				, title       = $translateResource( uri="email.template.#templateId#:title"      , defaultValue=templateId )
				, description = $translateResource( uri="email.template.#templateId#:description", defaultValue=""         )
			});
		}

		ArraySort( templates, function( a, b ){
			return CompareNoCase( a.title, b.title );
		} );

		return templates;
	}

	public array function listTemplatesGrouped() {
		var allTemplates = listTemplates();
		var grouped      = {};
		var groups       = [];

		if ( ArrayLen( allTemplates ) ) {
			grouped.default = allTemplates;
		}

		for( var template in allTemplates ) {
			if ( Len( template.group ?: "" ) ) {
				grouped[ template.group ] = grouped[ template.group ] ?: [];
				ArrayAppend( grouped[ template.group ], template );
			}
		}

		for( var group in grouped ) {
			ArrayAppend( groups, {
				  id        = group
				, label     = $translateResource( uri="email.templateGroups:#group#.label", defaultValue=group )
				, templates = grouped[ group ]
			} );
		}

		ArraySort( groups, function( a, b ){
			if ( a.id == "default" ) {
				return -1;
			} else if ( b.id == "default" ) {
				return 1;
			}
			if ( a.id == "unclassified" ) {
				return 1;
			} else if ( b.id == "unclassified" ) {
				return -1;
			}
			return CompareNoCase( a.label, b.label );
		} );

		return groups;
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
	 * Reset the provided system email template
	 *
	 * @autodoc  true
	 * @template The ID of the template to reset
	 *
	 */
	public void function resetTemplate( required string template ) {
		emailTemplateService.saveTemplate(
			  id       = arguments.template
			, template = {
				  name                      = $translateResource( uri="email.template.#arguments.template#:title", defaultValue=arguments.template )
				, layout                    = getDefaultLayout( arguments.template )
				, subject                   = getDefaultSubject( arguments.template )
				, html_body                 = getDefaultHtmlBody( arguments.template )
				, text_body                 = getDefaultTextBody( arguments.template )
				, recipient_type            = getRecipientType( arguments.template )
				, is_system_email           = true
				, body_changed_from_default = false
			}
		);
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
	 * @args.hint           A struct of args that have been passed to the email sending logic that will inform the building of this email
	 * @templateDetail.hint Struct with details of the template whose parameters are to be prepared
 	 * @detectedParams.hint Array of parameter names that have been detected in the content - providers can use this to restrict the rendering of parameters to only those necessary
	 *
	 */
	public struct function prepareParameters(
		  required string template
		,          struct args           = {}
		,          struct templateDetail = {}
		,          array  detectedParams
	) {
		var handlerAction = "email.template.#arguments.template#.prepareParameters";
		var prepArgs      = arguments.args.copy();

		prepArgs.templateDetail = arguments.templateDetail;
		if ( StructKeyExists( arguments, "detectedParams" ) ) {
			prepArgs.detectedParams = arguments.detectedParams;
		}

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


	public void function applicationStart() {
		if ( $isFeatureEnabled( "emailcenter" ) ) {
			$createTask(
				  event             = "admin.emailCenter.systemTemplates.checkForTemplatesWithNonDefaultBody"
				, runIn             = CreateTimespan( 0, 0, 1, 30 )
				, discardOnComplete = true
			);
		}
	}

	public boolean function bodyIsChangedFromDefault( required string template, string htmlBody, string textBody ) {
		var templateDetail = emailTemplateService.getTemplate( id=arguments.template );
		var htmlBody       = arguments.htmlBody ?: templateDetail.html_body;
		var textBody       = arguments.textBody ?: templateDetail.text_body;
		var defaultHtml    = getDefaultHtmlBody( template=arguments.template );
		var defaultText    = getDefaultTextBody( template=arguments.template );

		return ( _htmlIsDifferent( htmlBody, defaultHtml ) || _textIsDifferent( textBody, defaultText ) );
	}

	public array function templatesWithNonDefaultBody() {
		var templates = $getPresideObject( "email_template" ).selectData(
			  selectFields = [ "id" ]
			, filter       = { is_system_email=true, body_changed_from_default=true }
		);

		return ValueArray( templates.id );
	}

	public void function checkForTemplatesWithNonDefaultBody() {
		var dao       = $getPresideObject( "email_template" );
		var templates = dao.selectData(
			  filter       = { is_system_email=true }
			, selectFields = [ "id", "body_changed_from_default", "html_body", "text_body" ]
		);

		for( var template in templates ) {
			var bodyChanged = bodyIsChangedFromDefault( template=template.id, htmlBody=template.html_body, textBody=template.text_body );
			if ( bodyChanged != template.body_changed_from_default ) {
				dao.updateData( id=template.id, data={ body_changed_from_default=bodyChanged } );
			}
		}
	}


// PRIVATE HELPERS
	private string function _htmlIsDifferent( required string input1, required string input2 ) {
		return _htmlForComparison( arguments.input1 ) != _htmlForComparison( arguments.input2 );
	}
	private string function _textIsDifferent( required string input1, required string input2 ) {
		return _textForComparison( arguments.input1 ) != _textForComparison( arguments.input2 );
	}
	private string function _htmlForComparison( required string text ) {
		return encodeForHTML( ReReplace( arguments.text, "\s", "", "all" ), true );
	}
	private string function _textForComparison( required string text ) {
		return ReReplace( arguments.text, "\s", "", "all" );
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