component extends="preside.system.base.Service" output=false {

// CONSTRUCTOR
	public any function init(
		  required struct configuredWidgets
		, required any    formsService
		, required any    coldbox
		, required array  autoDiscoverDirectories
	) output=false {
		super.init( argumentCollection = arguments );

		_setFormsService( arguments.formsService );
		_setColdbox( arguments.coldbox );
		_setAutoDicoverDirectories( arguments.autoDiscoverDirectories );
		_setConfiguredWidgets( arguments.configuredWidgets );

		_autoDiscoverWidgets();
		_loadWidgetsFromConfig();

		return this;
	}

// PUBLIC API
	public struct function getWidgets() output=false {
		return _getWidgets();
	}

	public boolean function widgetExists( required string widgetId ) output=false {
		return StructKeyExists( _getWidgets(), arguments.widgetId );
	}

	public struct function getWidget( required string widgetId ) output=false {
		var widgets = _getWidgets();

		return widgets[ arguments.widgetId ] ?: {};
	}

	public string function renderWidget( required string widgetId, string configJson="", string context="", struct config={} ) output=false {
		var viewletArgs = Duplicate( arguments.config );

		if ( Len( Trim( arguments.configJson ) ) ) {
			StructAppend( viewletArgs, deserializeConfig( arguments.configJson ) );
		}
		viewletArgs.context = arguments.context;

		return _getColdbox().renderViewlet(
			  event = _getViewletEventForWidget( arguments.widgetId, arguments.context )
			, args  = viewletArgs
		);
	}

	public string function renderWidgetConfigForm( required string widgetId, string configJson="", string context="container", any validationResult="" ) output=false {
		var savedConfig  = "";

		if ( widgetHasConfigForm( arguments.widgetId ) ) {
			savedConfig  = Len( Trim( arguments.configJson ) ) ? deserializeConfig( arguments.configJson ) : {};

			return _getFormsService().renderForm(
				  formName         = _getConfigFormForWidget( arguments.widgetId )
				, context          = arguments.context
				, formId           = "widget-" & arguments.widgetId
				, validationResult = arguments.validationResult
				, savedData        = savedConfig
			);
		} else {
			return _getColdbox().renderViewlet(
				  event = "admin.widgets.noConfigRequired"
				, args  = { widget = getWidget( arguments.widgetId ) }
			);
		}

	}

	public boolean function widgetHasConfigForm( required string widgetId ) output=false {
		return _getFormsService().formExists( _getConfigFormForWidget( arguments.widgetId ) );
	}

	public string function getConfigFormForWidget( required string widgetId ) output=false {
		return _getConfigFormForWidget( arguments.widgetId );
	}

	public any function validateWidgetConfig( required string widgetId, required struct config ) output=false {
		return _getFormsService().validateForm(
			  formName = _getConfigFormForWidget( arguments.widgetId )
			, formData = arguments.config
		);
	}

	public struct function deserializeConfig( required string configJson ) output=false {
		var config = {};

		try {
			config = DeSerializeJson( UrlDecode( configJson ) );
		} catch ( any e ) {
			config = {};
		}

		if ( not IsStruct( config ) ) {
			config = {};
		}

		return config;
	}

	public string function renderEmbeddedWidgets( required string richContent, string context="" ) output=false {
		var embeddedWidget      = "";
		var renderedWidget      = "";
		var renderedContent = arguments.richContent;

		do {
			embeddedWidget = _findNextEmbeddedWidget( renderedContent );

			if ( StructCount( embeddedWidget ) ) {
				renderedWidget = renderWidget(
					  widgetId = embeddedWidget.id
					, configJson     = embeddedWidget.configJson
					, context        = arguments.context
				);

				renderedContent = Replace( renderedContent, embeddedWidget.placeholder, renderedWidget, "all" );
			}

		} while ( StructCount( embeddedWidget ) );

		return renderedContent;
	}

	public void function reload( struct configuredWidgets={} ) output=false {
		_autoDiscoverWidgets();
		_loadWidgetsFromConfig();
	}

// PRIVATE HELPERS
	private void function _loadWidgetsFromConfig() output=false {
		var widgets           = _getWidgets();
		var configuration = _getConfiguredWidgets();

		for( var widgetId in configuration ){
			widgets[ widgetId ] = Duplicate( configuration[ widgetId ] );

			widgets[ widgetId ].id          = widgetId;
			widgets[ widgetId ].configForm  = widgets[ widgetId ].configForm  ?: _getFormNameByConvention( widgetId );
			widgets[ widgetId ].viewlet     = widgets[ widgetId ].viewlet     ?: _getViewletEventByConvention( widgetId );
			widgets[ widgetId ].icon        = widgets[ widgetId ].icon        ?: _getIconByConvention( widgetId );
			widgets[ widgetId ].title       = widgets[ widgetId ].title       ?: _getTitleByConvention( widgetId );
			widgets[ widgetId ].description = widgets[ widgetId ].description ?: _getDescriptionByConvention( widgetId );
		}

		_setWidgets( widgets );
	}

	private void function _autoDiscoverWidgets() output=false {
		var widgets                     = {};
		var viewsPath               = "/views/widgets";
		var handlersPath            = "/handlers/widgets";
		var ids                     = {};
		var autoDiscoverDirectories = _getAutoDicoverDirectories();

		for( var dir in autoDiscoverDirectories ) {
			dir = ReReplace( dir, "/$", "" );
			var views    = DirectoryList( dir & viewsPath   , false, "query" );
			var handlers = DirectoryList( dir & handlersPath, false, "query", "*.cfc" );

			for ( var view in views ) {
				if ( views.type eq "Dir" ) {
					ids[ views.name ] = 1;
				} elseif ( views.type eq "File" and ReFindNoCase( "\.cfm$", views.name ) ) {
					ids[ ReReplaceNoCase( views.name, "\.cfm$", "" ) ] = 1;
				}
			}

			for ( var handler in handlers ) {
				if ( handlers.type eq "File" ) {
					ids[ ReReplace( handlers.name, "\.cfc$", "" ) ] = 1;
				}
			}
		}

		for( var id in ids ) {
			widgets[ id ].id          = id;
			widgets[ id ].configForm  = _getFormNameByConvention( id );
			widgets[ id ].viewlet     = _getViewletEventByConvention( id );
			widgets[ id ].icon        = _getIconByConvention( id );
			widgets[ id ].title       = _getTitleByConvention( id );
			widgets[ id ].description = _getDescriptionByConvention( id );
		}

		_setWidgets( widgets );
	}

	private struct function _getWidget( required string widgetId ) output=false {
		var widgets = _getWidgets();

		if ( StructKeyExists( widgets, arguments.widgetId ) ) {
			return widgets[ arguments.widgetId ];
		}

		throw( type="widgets.missingWidget", message="The widget, [#widgetId#], could not be found" );
	}

	private string function _getWidgetProperty( required string widgetId, required string propertyName ) output=false {
		var widget = _getWidget( widgetId );

		return widget[ arguments.propertyName ] ?: "";
	}

	private string function _getViewletEventForWidget( required string widgetId ) output=false {
		return _getWidgetProperty( widgetId, "viewlet" );
	}

	private string function _getConfigFormForWidget( required string widgetId ) output=false {
		return _getWidgetProperty( widgetId, "configForm" );
	}

	private string function _getFormNameByConvention( required string widgetId ) output=false {
		return "widgets." & widgetId;
	}

	private string function _getViewletEventByConvention( required string widgetId ) output=false {
		return "widgets." & widgetId;
	}

	private string function _getIconByConvention( required string widgetId ) output=false {
		return "widgets.#widgetId#:iconclass";
	}

	private string function _getTitleByConvention( required string widgetId ) output=false {
		return "widgets.#widgetId#:title";
	}

	private string function _getDescriptionByConvention( required string widgetId ) output=false {
		return "widgets.#widgetId#:description";
	}

	private struct function _findNextEmbeddedWidget( required string richContent ) output=false {
		// The following regex is designed to match the following pattern that would be embedded in rich editor content:
		// {{widget:myWidgetId:{option:"value",option2:"value"}:widget}}


		var regex = "{{widget:([a-z\$_][a-z0-9\$_]*):(.*?):widget}}";
		var match = ReFindNoCase( regex, arguments.richContent, 1, true );
		var widget    = {};

		if ( ArrayLen( match.len ) eq 3 and match.len[1] and match.len[2] and match.len[3] ) {
			widget.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );
			widget.id          = Mid( arguments.richContent, match.pos[2], match.len[2] );
			widget.configJson  = Mid( arguments.richContent, match.pos[3], match.len[3] );
		}

		return widget;
	}


// GETTERS AND SETTERS
	private any function _getFormsService() output=false {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) output=false {
		_formsService = arguments.formsService;
	}

	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}

	private struct function _getWidgets() output=false {
		return _widgets;
	}
	private void function _setWidgets( required struct widgets ) output=false {
		_widgets = arguments.widgets;
	}

	private array function _getAutoDicoverDirectories() output=false {
		return _autoDicoverDirectories;
	}
	private void function _setAutoDicoverDirectories( required array autoDicoverDirectories ) output=false {
		_autoDicoverDirectories = arguments.autoDicoverDirectories;
	}

	private struct function _getConfiguredWidgets() output=false {
		return _configuredWidgets;
	}
	private void function _setConfiguredWidgets( required struct configuredWidgets ) output=false {
		_configuredWidgets = arguments.configuredWidgets;
	}
}