/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredWidgets.inject       coldbox:setting:widgets
	 * @formsService.inject            FormsService
	 * @coldbox.inject                 coldbox
	 * @autoDiscoverDirectories.inject presidecms:directories
	 * @i18nPlugin.inject              i18n
	 * @featureService.inject          featureService
	 * @siteService.inject             siteService
	 */
	public any function init(
		  required struct configuredWidgets
		, required any    formsService
		, required any    coldbox
		, required array  autoDiscoverDirectories
		, required any    i18nPlugin
		, required any    featureService
		, required any    siteService
	) {
		_setFormsService( arguments.formsService );
		_setColdbox( arguments.coldbox );
		_setAutoDicoverDirectories( arguments.autoDiscoverDirectories );
		_setConfiguredWidgets( arguments.configuredWidgets );
		_setI18nPlugin( arguments.i18nPlugin );
		_setFeatureService( arguments.featureService );
		_setSiteService( arguments.siteService );

		_autoDiscoverWidgets();
		_loadWidgetsFromConfig();

		return this;
	}

// PUBLIC API
	public struct function getWidgets( array categories=[] ) {
		var widgets = Duplicate( _getWidgets() );

		for( var widgetId in widgets ) {
			if ( !_isWidgetEnabled( widgetId, true ) || !_isWidgetInCategories( widgetId, arguments.categories ) ) {
				widgets.delete( widgetId );
			}
		}

		return widgets;
	}

	public boolean function widgetExists( required string widgetId ) {
		return StructKeyExists( _getWidgets(), arguments.widgetId ) && _isWidgetEnabled( arguments.widgetId, true );
	}

	public struct function getWidget( required string widgetId ) {
		var widgets = _getWidgets();

		return widgets[ arguments.widgetId ] ?: {};
	}

	public string function renderWidget( required string widgetId, string configJson="", string context="", struct config={} ) {
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

	public string function renderWidgetConfigForm( required string widgetId, string configJson="", string context="container", any validationResult="" ) {
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

	public string function renderWidgetPlaceholder( required string widgetId, string configJson="" ) {
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

	public boolean function widgetHasConfigForm( required string widgetId ) {
		return _getFormsService().formExists( _getConfigFormForWidget( arguments.widgetId ) );
	}

	public string function getConfigFormForWidget( required string widgetId ) {
		return _getConfigFormForWidget( arguments.widgetId );
	}

	public any function validateWidgetConfig( required string widgetId, required struct config ) {
		return _getFormsService().validateForm(
			  formName = _getConfigFormForWidget( arguments.widgetId )
			, formData = arguments.config
		);
	}

	public struct function deserializeConfig( required string configJson ) {
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

	public void function reload( struct configuredWidgets={} ) {
		_autoDiscoverWidgets();
		_loadWidgetsFromConfig();
	}

// PRIVATE HELPERS
	private void function _loadWidgetsFromConfig() {
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

	private void function _autoDiscoverWidgets() {
		var widgets                 = {};
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
				} else if ( views.type == "File" && ReFindNoCase( "\.cfm$", views.name ) && !views.name.reFind( "^_" ) ) {
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
			if ( _isWidgetEnabled( id ) ) {
				widgets[ id ] = {
					  id                 = id
					, configForm         = _getFormNameByConvention( id )
					, viewlet            = _getViewletEventByConvention( id )
					, placeholderViewlet = _getPlaceholderViewletEventByConvention( id )
					, icon               = _getIconByConvention( id )
					, title              = _getTitleByConvention( id )
					, description        = _getDescriptionByConvention( id )
					, siteTemplates      = _mergeSiteTemplates( siteTemplateMap[id] )
					, categories         = _getWidgetCategoriesFromForm( id )
				};
			}
		}

		_setWidgets( widgets );
	}

	private struct function _getWidget( required string widgetId ) {
		var widgets = _getWidgets();

		if ( StructKeyExists( widgets, arguments.widgetId ) ) {
			return widgets[ arguments.widgetId ];
		}

		throw( type="widgets.missingWidget", message="The widget, [#widgetId#], could not be found" );
	}

	private string function _getWidgetProperty( required string widgetId, required string propertyName ) {
		var widget = _getWidget( widgetId );

		return widget[ arguments.propertyName ] ?: "";
	}

	private string function _getViewletEventForWidget( required string widgetId ) {
		return _getWidgetProperty( widgetId, "viewlet" );
	}

	private string function _getPlaceholderViewletEventForWidget( required string widgetId ) {
		return _getWidgetProperty( widgetId, "placeholderViewlet" );
	}

	private string function _getConfigFormForWidget( required string widgetId ) {
		return _getWidgetProperty( widgetId, "configForm" );
	}

	private string function _getFormNameByConvention( required string widgetId ) {
		return "widgets." & widgetId;
	}

	private array function _getWidgetCategoriesFromForm( required string widgetId ) {
		var formName = _getFormNameByConvention( arguments.widgetId );

		if ( _getFormsService().formExists( formName ) ) {
			var theForm = _getFormsService().getForm( formName );

			return ListToArray( theForm.categories ?: "" );
		}

		return [];
	}

	private string function _getViewletEventByConvention( required string widgetId ) {
		return "widgets." & widgetId;
	}

	private string function _getPlaceholderViewletEventByConvention( required string widgetId ) {
		return "widgets." & widgetId & ".placeholder";
	}

	private string function _getIconByConvention( required string widgetId ) {
		return "widgets.#widgetId#:iconclass";
	}

	private string function _getTitleByConvention( required string widgetId ) {
		return "widgets.#widgetId#:title";
	}

	private string function _getDescriptionByConvention( required string widgetId ) {
		return "widgets.#widgetId#:description";
	}

	private string function _getSiteTemplateFromPath( required string path ) {
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

	private boolean function _isWidgetEnabled( required string widget, boolean includeSiteTemplate=false ) {
		var featureService = _getFeatureService();
		var widgetFeature  = featureService.getFeatureForWidget( arguments.widget );

		if ( widgetFeature.len() ) {
			return featureService.isFeatureEnabled(
				  feature       = widgetFeature
				, siteTemplate  = ( arguments.includeSiteTemplate ? _getSiteService().getActiveSiteTemplate() : NullValue() )
			);
		}

		return true;
	}

	private boolean function _isWidgetInCategories( required string widgetId, required array categories ) {
		var widgetCategories = getWidget( arguments.widgetId ).categories ?: [];

		if ( !widgetCategories.len() ) {
			widgetCategories = [ "default" ];
		}

		if ( !arguments.categories.len() ) {
			arguments.categories = [ "default" ];
		}

		for( var widgetCategory in widgetCategories ) {
			if ( arguments.categories.findNoCase( widgetCategory ) ) {
				return true;
			}
		}

		return false;
	}


// GETTERS AND SETTERS
	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}

	private any function _getColdbox() {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) {
		_coldbox = arguments.coldbox;
	}

	private struct function _getWidgets() {
		return _widgets;
	}
	private void function _setWidgets( required struct widgets ) {
		_widgets = arguments.widgets;
	}

	private array function _getAutoDicoverDirectories() {
		return _autoDicoverDirectories;
	}
	private void function _setAutoDicoverDirectories( required array autoDicoverDirectories ) {
		_autoDicoverDirectories = arguments.autoDicoverDirectories;
	}

	private struct function _getConfiguredWidgets() {
		return _configuredWidgets;
	}
	private void function _setConfiguredWidgets( required struct configuredWidgets ) {
		_configuredWidgets = arguments.configuredWidgets;
	}

	private any function _getI18nPlugin() {
		return _i18nPlugin;
	}
	private void function _setI18nPlugin( required any i18nPlugin ) {
		_i18nPlugin = arguments.i18nPlugin;
	}

	private any function _getFeatureService() {
		return _featureService;
	}
	private void function _setFeatureService( required any featureService ) {
		_featureService = arguments.featureService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}
}