/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 *
 */
component {

	/**
	 * @systemEmailTemplateService.inject systemEmailTemplateService
	 *
	 */
	public any function init( required any systemEmailTemplateService ) {
		_setSystemEmailTemplateService( arguments.systemEmailTemplateService );
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
	public query function getTemplate( required string id ){
		return $getPresideObject( "email_template" ).selectData( id=arguments.id );
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
}