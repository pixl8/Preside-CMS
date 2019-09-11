/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 *
 */
component {

	/**
	 * @viewletsService.inject viewletsService
	 * @formsService.inject    formsService
	 *
	 */
	public any function init( required any viewletsService, required any formsService ) {
		_setViewletsService( arguments.viewletsService );
		_setFormsService( arguments.formsService );

		_loadLayoutsFromViewlets();

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of structs describing the application's
	 * available email layouts. Each struct contains `id`, `title`
	 * and `description` keys. Layouts are ordered by title (ascending).
	 *
	 * @autodoc
	 *
	 */
	public array function listLayouts() {
		var layoutIds = _getLayouts();
		var layouts   = [];

		for( var layoutId in layoutIds ) {
			layouts.append( getLayout( layoutId ) );
		}

		layouts.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return layouts;
	}

	/**
	 * Returns a struct with details of the given layout.
	 *
	 * @autodoc
	 * @layout.hint ID of the layout you wish to get
	 */
	public struct function getLayout( required string layout ) {
		var formsService = _getFormsService();

		if ( layoutExists( arguments.layout ) ) {
			return {
				  id           = arguments.layout
				, title        = $translateResource( uri="email.layout.#arguments.layout#:title"      , defaultValue=arguments.layout )
				, description  = $translateResource( uri="email.layout.#arguments.layout#:description", defaultValue=""       )
				, configurable = formsService.formExists( "email.layout.#arguments.layout#" )
			};
		}

		return {};
	}

	/**
	 * Returns whether or not the given layout
	 * exists within the system.
	 *
	 * @autodoc true
	 * @layout  The ID of the layout whose existance you want to check
	 *
	 */
	public boolean function layoutExists( required string layout ) {
		return _getLayouts().findNoCase( arguments.layout ) > 0;
	}

	/**
	 * Returns the rendering of an email layout with the given
	 * arguments.
	 *
	 * @autodoc              true
	 * @layout.hint          ID of the layout to render
	 * @emailTemplate.hint   ID of the email template that is being rendered within the layout
	 * @blueprint.hint       ID of the email blueprint that the template uses
	 * @type.hint            Type of render, either HTML or TEXT
	 * @subject.hint         Subject of the email
	 * @body.hint            Body of the email
	 * @unsubscribeLink.hint Optional link for unsubscribing from emails
	 * @viewOnlineLink.hint  Optional link for viewling email online
	 *
	 */
	public string function renderLayout(
		  required string layout
		, required string emailTemplate
		, required string blueprint
		, required string type
		, required string subject
		, required string body
		,          string unsubscribeLink = ""
		,          string viewOnlineLink  = ""
		,          struct templateDetail  = {}
	) {
		$announceInterception( "preRenderEmailLayout", arguments );

		var renderType   = arguments.type == "text" ? "text" : "html";
		var viewletEvent = "email.layout.#arguments.layout#.#renderType#";
		var viewletArgs  = {};

		for( var key in arguments ) {
			if ( ![ "layout", "type", "emailTemplate", "blueprint", "templateDetail" ].findNoCase( key ) ) {
				viewletArgs[ key ] = arguments[ key ];
			}
		}

		var config = getLayoutConfig(
			  layout        = arguments.layout
			, emailTemplate = arguments.emailTemplate
			, blueprint     = arguments.blueprint
			, merged        = true
		);
		viewletArgs.append( config, false );
		viewletArgs.append( arguments.templateDetail, false );

		var interceptorArgs = {
			  rendered = $renderViewlet( event=viewletEvent, args=viewletArgs )
			, args     = arguments
		};

		$announceInterception( "postRenderEmailLayout", interceptorArgs );

		return interceptorArgs.rendered;
	}

	/**
	 * Returns the form name used for configuring the
	 * given layout. If the layout does not exist, or
	 * does not have a corresponding configuration form,
	 * an empty string is returned.
	 *
	 * @autodoc     true
	 * @layout.hint ID of the layout whose form name you wish to get
	 */
	public string function getLayoutConfigFormName( required string layout ) {
		if ( layoutExists( arguments.layout ) ) {
			var formName = 'email.layout.#arguments.layout#';

			if ( _getFormsService().formExists( formName ) ) {
				return 'email.layout.#arguments.layout#';
			}
		}

		return "";
	}

	/**
	 * Saves the given layout configuration in the database.
	 *
	 * @autodoc            true
	 * @layout.hint        ID of the layout whose configuration you want to save
	 * @config.hint        Struct of configuration data to save
	 * @emailTemplate.hint Optional ID of a specific email template whose layout configuration you wish to save
	 * @blueprint.hint     Optional ID of a specific email blueprint whose layout configuration you wish to save
	 *
	 */
	public boolean function saveLayoutConfig(
		  required string layout
		, required struct config
		,          string emailTemplate = ""
		,          string blueprint     = ""
	){
		var configDao = $getPresideObject( "email_layout_config_item" );

		transaction {
			configDao.deleteData( filter={ layout=arguments.layout, email_template=arguments.emailTemplate, email_blueprint=arguments.blueprint } );

			for( var item in arguments.config ) {
				configDao.insertData( {
					  layout          = arguments.layout
					, item            = item
					, value           = arguments.config[ item ]
					, email_template  = arguments.emailTemplate
					, email_blueprint = arguments.blueprint
				});
			}
		}

		return true;
	}

	/**
	 * Returns the saved config for an email layout and optional email template combination.
	 *
	 * @autodoc            true
	 * @layout.hint        ID of the layout whose configuration you wish to get
	 * @emailTemplate.hint Optional ID of specific email template whose layout configuration you wish to get
	 * @blueprint.hint     Optional ID of specific email blueprint whose layout configuration you wish to get
	 * @merged.hint        If true, and layout, emailTemplate and blueprint supplied, the method will return a combined set of settings (global, blueprint + template specific)
	 */
	public struct function getLayoutConfig(
		  required string  layout
		,          string  emailTemplate = ""
		,          string  blueprint     = ""
		,          boolean merged        = false
	) {
		var config      = {};
		var savedConfig = "";

		if ( !merged ) {
			savedConfig = $getPresideObject( "email_layout_config_item" ).selectData(
				  filter = { layout=arguments.layout, email_template=arguments.emailTemplate, email_blueprint=arguments.blueprint }
				, selectFields = [ "item", "value" ]
			);
			for( var record in savedConfig ) {
				config[ record.item ] = record.value;
			}
		} else {
			savedConfig = $getPresideObject( "email_layout_config_item" ).selectData(
				  filter = { layout=arguments.layout, email_template="", email_blueprint="" }
				, selectFields = [ "item", "value" ]
			);
			for( var record in savedConfig ) {
				config[ record.item ] = record.value;
			}

			if ( Len( Trim( arguments.blueprint ) ) ) {
				savedConfig = $getPresideObject( "email_layout_config_item" ).selectData(
					  filter = { layout=arguments.layout, email_template="", email_blueprint=arguments.blueprint }
					, selectFields = [ "item", "value" ]
				);
				for( var record in savedConfig ) {
					config[ record.item ] = record.value;
				}
			}

			if ( Len( Trim( arguments.emailTemplate ) ) ) {
				savedConfig = $getPresideObject( "email_layout_config_item" ).selectData(
					  filter = { layout=arguments.layout, email_template=arguments.emailTemplate, email_blueprint="" }
					, selectFields = [ "item", "value" ]
				);
				for( var record in savedConfig ) {
					config[ record.item ] = record.value;
				}
			}
		}

		return config;
	}

// PRIVATE HELPERS
	private void function _loadLayoutsFromViewlets() {
		var viewletRegex     = "email\.layout\.(.*?)\.(html|text)";
		var matchingViewlets = _getViewletsService().listPossibleViewlets( filter="email\.layout\.(.*?)\.(html|text)" );
		var layouts          = {};

		for( var viewlet in matchingViewlets ){
			layouts[ viewlet.reReplace( viewletRegex, "\1" ) ] = true;
		}

		_setLayouts( layouts.keyArray() );
	}

// GETTERS AND SETTERS
	private array function _getLayouts() {
		return _layouts;
	}
	private void function _setLayouts( required array layouts ) {
		_layouts = arguments.layouts;
	}

	private any function _getViewletsService() {
		return _viewletsService;
	}
	private void function _setViewletsService( required any viewletsService ) {
		_viewletsService = arguments.viewletsService;
	}

	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}
}