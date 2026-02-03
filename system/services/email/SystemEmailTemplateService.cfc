/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        emailCenter
 */
component {
	property name="emailTemplateService" inject="delayedInjector:emailTemplateService";

	/**
	 * @configuredTemplates.inject  coldbox:setting:email.templates
	 */
	public any function init( required struct configuredTemplates ) {
		_setConfiguredTemplates( arguments.configuredTemplates );
		_initVariantTemplateLookupCache();

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
	public array function listTemplates( string group="" ) {
		var allTemplates = _getConfiguredTemplates();
		var templateIds  = StructKeyArray( allTemplates );
		var templates    = [];

		for( var templateId in templateIds ) {
			var template      = allTemplates[ templateId ];
			var templateGroup = template.group ?: "unclassified";
			if ( !Len( arguments.group ) || arguments.group==templateGroup ) {
				ArrayAppend( templates, {
					  id            = templateId
					, group         = templateGroup
					, allowVariants = $helpers.isTrue( template.allowVariants ?: "" )
					, title         = $translateResource( uri="email.template.#templateId#:title"      , defaultValue=templateId )
					, description   = $translateResource( uri="email.template.#templateId#:description", defaultValue=""         )
				});
			}
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
		var baseTemplateId = _getBaseTemplateId( arguments.template );

		return StructKeyExists( _getConfiguredTemplates(), baseTemplateId );
	}

	/**
	 * Reset the provided system email template
	 *
	 * @autodoc  true
	 * @template The ID of the template to reset
	 *
	 */
	public void function resetTemplate( required string template ) {
		var templateData = {
			  subject                   = getDefaultSubject( arguments.template )
			, html_body                 = getDefaultHtmlBody( arguments.template )
			, text_body                 = getDefaultTextBody( arguments.template )
			, recipient_type            = getRecipientType( arguments.template )
			, is_system_email           = true
			, body_changed_from_default = false
		};
		if ( !isVariant( arguments.template ) ) {
			templateData.name = $translateResource( uri="email.template.#arguments.template#:title", defaultValue=arguments.template );
		}

		emailTemplateService.saveTemplate( id=arguments.template, template=templateData );
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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var templateParams = templates[ baseTemplateId ].parameters ?: [];

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

			translatedParam.title       = $translateResource( uri="email.template.#baseTemplateId#:param.#translatedParam.id#.title"      , defaultValue=translatedParam.id );
			translatedParam.description = $translateResource( uri="email.template.#baseTemplateId#:param.#translatedParam.id#.description", defaultValue="" );

			ArrayAppend( params, translatedParam );
		}

		ArraySort( params, function( a, b ){
			return CompareNoCase( a.title, b.title );
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
		var templates      = _getConfiguredTemplates();
		var baseTemplateId = _getBaseTemplateId( arguments.template );

		return templates[ baseTemplateId ].saveContent ?: true;
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
		var templates      = _getConfiguredTemplates();
		var baseTemplateId = _getBaseTemplateId( arguments.template );

		return templates[ baseTemplateId ].contentExpiry ?: "";
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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var handlerAction  = "email.template.#baseTemplateId#.prepareParameters";
		var prepArgs       = arguments.args.copy();

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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var handlerAction  = "email.template.#baseTemplateId#.getPreviewParameters";

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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var handlerAction  = "email.template.#baseTemplateId#.prepareAttachments";

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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var handlerAction  = "email.template.#baseTemplateId#.rebuildArgsForResend";

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
		var templates      = _getConfiguredTemplates();
		var baseTemplateId = _getBaseTemplateId( arguments.template );

		return templates[ baseTemplateId ].layout ?: "default";
	}

	/**
	 * Returns the default subject for a given template, derived from its 'defaultSubject'
	 * viewlet.
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose default subject you wish to get
	 */
	public string function getDefaultSubject( required string template ) {
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var viewlet        = "email.template.#baseTemplateId#.defaultSubject";

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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var viewlet        = "email.template.#baseTemplateId#.defaultHtmlBody";

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
		var baseTemplateId = _getBaseTemplateId( arguments.template );
		var viewlet        = "email.template.#baseTemplateId#.defaultTextBody";

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
		var templates      = _getConfiguredTemplates();
		var baseTemplateId = _getBaseTemplateId( arguments.template );

		return templates[ baseTemplateId ].recipientType ?: "anonymous";
	}

	/**
	 * Returns a boolean defining whether a system template allows variants to be created
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose variant setting you wish to get
	 *
	 */
	public boolean function allowVariants( required string template ) {
		var templates = _getConfiguredTemplates();

		return $helpers.isTrue( templates[ arguments.template ].allowVariants ?: "" );
	}

	/**
	 * Returns a boolean defining whether a template is a variant
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose variant status you wish to check
	 *
	 */
	public boolean function isVariant( required string template ) {
		return $getPresideObject( "email_template" ).dataExists(
			  filter       = { id=arguments.template, is_system_email=true }
			, extraFilters = [ { filter="variant_of is not null" } ]
		);
	}

	/**
	 * Returns a query containing all the defined variants of a system template
	 *
	 * @autodoc       true
	 * @template.hint ID of the template whose variants you wish to get
	 *
	 */
	public query function getVariants( required string template ) {
		return $getPresideObject( "email_template" ).selectData(
			  filter       = { variant_of=arguments.template }
			, selectFields = [ "id", "name", "subject", "layout" ]
			, orderBy      = "name"
		);
	}

	/**
	 * Adds a new variant of a system template
	 *
	 * @autodoc   true
	 * @variantOf The ID of the template the variant is a child of
	 * @name      The name of the new variant
	 *
	 */
	public string function addVariant( required string variantOf, required string name ) {
		var template  = emailTemplateService.getTemplate( id=arguments.variantOf );
		var variantId = "";

		if ( StructCount( template ) ) {
			variantId = emailTemplateService.saveTemplate( template={
				  name            = arguments.name
				, variant_of      = arguments.variantOf
				, layout          = template.layout
				, subject         = template.subject
				, html_body       = template.html_body
				, text_body       = template.text_body
				, recipient_type  = template.recipient_type
				, is_system_email = true
			} );
		}

		return variantId;
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
	private string function _getBaseTemplateId( required string template ) {
		if ( StructKeyExists( _getConfiguredTemplates(), arguments.template ) ) {
			return arguments.template;
		}

		var variantTemplates = _getVariantTemplateLookupCache();
		if ( StructKeyExists( variantTemplates, arguments.template ) ) {
			return variantTemplates[ arguments.template ];
		}

		var variant = $getPresideObject( "email_template" ).selectData(
			  filter       = "id = :id and is_system_email = :is_system_email and variant_of is not null"
			, filterParams = { id=arguments.template, is_system_email=true }
			, selectFields = [ "variant_of" ]
		);

		if ( variant.recordcount ) {
			variantTemplates[ arguments.template ] = variant.variant_of;
			return variant.variant_of;
		}

		return "";
	}

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

			if ( !Len( feature ) || $isFeatureEnabled( feature ) ) {
				_configuredTemplates[ templateId ] = configuredTemplates[ templateId ];
			}
		}
	}

	private struct function _getVariantTemplateLookupCache() {
		return _variantTemplateLookupCache;
	}
	private void function _initVariantTemplateLookupCache() {
		_variantTemplateLookupCache = {};
	}

}