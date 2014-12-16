component singleton=true output=false {

// CONSTRUCTOR
	/**
	 * @configuredWidgets.inject       coldbox:setting:widgets
	 * @formsService.inject            FormsService
	 * @coldbox.inject                 coldbox
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @i18nPlugin.inject              coldbox:plugin:i18n
	 */
	public any function init(
		  required struct configuredWidgets
		, required any    formsService
		, required any    coldbox
		, required array  autoDiscoverDirectories
		, required any    i18nPlugin
	) output=false {
		_setFormsService( arguments.formsService );
		_setColdbox( arguments.coldbox );
		_setAutoDicoverDirectories( arguments.autoDiscoverDirectories );
		_setConfiguredWidgets( arguments.configuredWidgets );
		_setI18nPlugin( arguments.i18nPlugin );

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
		if ( !widgetExists( arguments.widgetId ) ) {
			return "";
		}

		var args = Duplicate( arguments.config );

		if ( Len( Trim( arguments.configJson ) ) ) {
			StructAppend( args, deserializeConfig( arguments.configJson ) );
		}
		args.context = arguments.context;

		return _getColdbox().renderViewlet(
			  event = _getViewletEventForWidget( arguments.widgetId, arguments.context )
			, args  = args
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

	public string function renderWidgetPlaceholder( required string widgetId, string configJson="" ) output=false {
		var rendered = "";

		if ( !widgetExists( arguments.widgetId ) ) {
			return "";
		}

		var viewlet = _getPlaceholderViewletEventForWidget( arguments.widgetId );
		if ( _getColdbox().viewletExists( viewlet ) ) {
			return _getColdbox().renderViewlet(
				  event = viewlet
				, args  = deserializeConfig( arguments.configJson )
			);
		}
		var widgetTitle = _getWidgetProperty( arguments.widgetId, "title" );

		return _getI18nPlugin().translateResource( uri=widgetTitle, defaultValue=widgetTitle );
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
		var siteTemplateMap         = {};

		for( var dir in autoDiscoverDirectories ) {
			dir              = ReReplace( dir, "/$", "" );
			var views        = DirectoryList( dir & viewsPath   , false, "query" );
			var handlers     = DirectoryList( dir & handlersPath, false, "query", "*.cfc" );
			var siteTemplate = _getSiteTemplateFromPath( dir );

			for ( var view in views ) {
				var id = "";
				if ( views.type eq "Dir" ) {
					id = views.name;
				} elseif ( views.type == "File" && ReFindNoCase( "\.cfm$", views.name ) && !views.name.startsWith( "_" ) ) {
					id = ReReplaceNoCase( views.name, "\.cfm$", "" );
				} else {
					continue;
				}

				ids[ id ] = 1;
				siteTemplateMap[ id ] = siteTemplateMap[ id ] ?: [];
				siteTemplateMap[ id ].append( siteTemplate );
			}

			for ( var handler in handlers ) {
				if ( handlers.type eq "File" ) {
					var id = ReReplace( handlers.name, "\.cfc$", "" );
					ids[ id ] = 1;

					siteTemplateMap[ id ] = siteTemplateMap[ id ] ?: [];
					siteTemplateMap[ id ].append( siteTemplate );
				}
			}
		}

		for( var id in ids ) {
			widgets[ id ].id                 = id;
			widgets[ id ].configForm         = _getFormNameByConvention( id );
			widgets[ id ].viewlet            = _getViewletEventByConvention( id );
			widgets[ id ].placeholderViewlet = _getPlaceholderViewletEventByConvention( id );
			widgets[ id ].icon               = _getIconByConvention( id );
			widgets[ id ].title              = _getTitleByConvention( id );
			widgets[ id ].description        = _getDescriptionByConvention( id );
			widgets[ id ].siteTemplates      = _mergeSiteTemplates( siteTemplateMap[id] );
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

	private string function _getPlaceholderViewletEventForWidget( required string widgetId ) output=false {
		return _getWidgetProperty( widgetId, "placeholderViewlet" );
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

	private string function _getPlaceholderViewletEventByConvention( required string widgetId ) output=false {
		return "widgets." & widgetId & ".placeholder";
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

	private string function _getSiteTemplateFromPath( required string path ) output=false {
		var regex = "^.*[\\/]site-templates[\\/]([^\\/]+)$";

		if ( !ReFindNoCase( regex, arguments.path ) ) {
			return "*";
		}

		return ReReplaceNoCase( arguments.path, regex, "\1" );
	}

	private string function _mergeSiteTemplates( required array templates ) ouptut=false {
		var merged = "";

		for( var template in arguments.templates ) {
			if ( template == "*" ) {
				return "*";
			}
			merged = ListAppend( merged, template );
		}

		return merged;
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

	private any function _getI18nPlugin() output=false {
		return _i18nPlugin;
	}
	private void function _setI18nPlugin( required any i18nPlugin ) output=false {
		_i18nPlugin = arguments.i18nPlugin;
	}
}