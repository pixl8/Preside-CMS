/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 *
 */
component {

	/**
	 * @systemEmailTemplateService.inject systemEmailTemplateService
	 * @emailRecipientTypeService.inject  emailRecipientTypeService
	 *
	 */
	public any function init(
		  required any systemEmailTemplateService
		, required any emailRecipientTypeService
	) {
		_setSystemEmailTemplateService( arguments.systemEmailTemplateService );
		_setEmailRecipientTypeService( arguments.emailRecipientTypeService );
		_ensureSystemTemplatesHaveDbEntries();

		return this;
	}

// PUBLIC API
	/**
	 * Inserts or updates the given email template
	 *
	 * @autodoc  true
	 * @template Struct containing fields to save
	 * @id       Optional ID of the template to save (if empty, assumes its a new template)
	 *
	 */
	public string function saveTemplate(
		  required struct template
		,          string id       = ""
	) {
		transaction {
			if ( Len( Trim( arguments.id ) ) ) {
				var updated = $getPresideObject( "email_template" ).updateData(
					  id   = arguments.id
					, data = arguments.template
				);

				if ( updated ) {
					return arguments.id;
				}

				arguments.template.id = arguments.id;

			}
			var newId = $getPresideObject( "email_template" ).insertData( data=arguments.template );

			return arguments.template.id ?: newId;
		}
	}

	/**
	 * Returns whether or not the given template exists in the database
	 *
	 * @autodoc true
	 * @id.hint ID of the template to check
	 */
	public boolean function templateExists( required string id ) {
		return $getPresideObject( "email_template" ).dataExists( id=arguments.id );
	}

	/**
	 * Returns the saved template from the database
	 *
	 * @autodoc true
	 * @id.hint ID of the template to get
	 *
	 */
	public struct function getTemplate( required string id ){
		var template = $getPresideObject( "email_template" ).selectData( id=arguments.id );

		for( var t in template ) {
			return t;
		}

		return {};
	}

	/**
	 * Replaces parameter tokens in strings (subject, body) with
	 * passed in values.
	 *
	 * @autodoc true
	 * @text    The raw text that contains the parameter tokens
	 * @params  A struct of params. Each param can either be a simple value or a struct with simple values for `html` and `text` keys
	 * @type    Either 'text' or 'html'
	 *
	 */
	public string function replaceParameterTokens(
		  required string text
		, required struct params
		, required string type
	) {
		arguments.type = arguments.type == "text" ? "text" : "html";
		var replaced = arguments.text;

		for( var paramName in arguments.params ) {
			var token = "${#paramName#}";
			var value = IsSimpleValue( arguments.params[ paramName ] ) ? arguments.params[ paramName ] : ( arguments.params[ paramName ][ arguments.type ] ?: "" );

			replaced = replaced.replaceNoCase( token, value, "all" );
		}

		return replaced;
	}

	/**
	 * Prepares params (for use in replacing tokens in subject and body)
	 * for the given email template, recipient type and sending args.
	 *
	 * @autodoc       true
	 * @template      ID of the template of the email that is being prepared
	 * @recipientType ID of the recipient type of the email that is being prepared
	 * @args          Structure of variables that are being used to send / prepare the email
	 */
	public struct function prepareParameters(
		  required string template
		, required string recipientType
		, required struct args
	) {
		var params = _getEmailRecipientTypeService().prepareParameters(
			  recipientType = arguments.recipientType
			, args          = arguments.args
		);

		if ( _getSystemEmailTemplateService().templateExists( arguments.template ) ) {
			params.append( _getSystemEmailTemplateService().prepareParameters(
				  template = arguments.template
				, args     = arguments.args
			) );
		}

		return params;
	}

// PRIVATE HELPERS
	private void function _ensureSystemTemplatesHaveDbEntries() {
		var sysTemplateService = _getSystemEmailTemplateService();
		var systemTemplates    = sysTemplateService.listTemplates();

		for( var template in systemTemplates ) {
			if ( !templateExists( template.id ) ) {
				saveTemplate( id=template.id, template={
					  name      = template.title
					, layout    = sysTemplateService.getDefaultLayout( template.id )
					, subject   = sysTemplateService.getDefaultSubject( template.id )
					, html_body = sysTemplateService.getDefaultHtmlBody( template.id )
					, text_body = sysTemplateService.getDefaultTextBody( template.id )
				} );
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getSystemEmailTemplateService() {
		return _systemEmailTemplateService;
	}
	private void function _setSystemEmailTemplateService( required any systemEmailTemplateService ) {
		_systemEmailTemplateService = arguments.systemEmailTemplateService;
	}

	private any function _getEmailRecipientTypeService() {
		return _emailRecipientTypeService;
	}
	private void function _setEmailRecipientTypeService( required any emailRecipientTypeService ) {
		_emailRecipientTypeService = arguments.emailRecipientTypeService;
	}
}