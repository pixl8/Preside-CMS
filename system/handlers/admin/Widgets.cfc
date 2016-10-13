component extends="preside.system.base.AdminHandler" output=false {

	property name="widgetsService" inject="widgetsService";
	property name="siteService"    inject="siteService";
	property name="messageBox"     inject="coldbox:plugin:messageBox";

	public void function dialog( event, rc, prc ) output=false {
		var widget            = rc.widget            ?: "";
		var configJson        = rc.configJson        ?: "";
		var widgetConfigSaved = rc.widgetConfigSaved ?: false;
		var savedConfig       = rc.savedConfig       ?: {};

		event.setLayout( "adminModalDialog" );

		if ( IsBoolean( widgetConfigSaved ) && widgetConfigSaved && Len( Trim( widget ) ) ) {
			if ( not IsStruct( savedConfig ) ) {
				savedConfig eq {};
			}

			event.includeData( { widgetSavedConfig = "{{widget:#Trim( widget )#:#Trim( UrlEncodedFormat( SerializeJson( savedConfig ) ) )#:widget}}" } );
			event.setView( "admin/widgets/configSavedDialog" );

		} elseif ( Len( Trim( rc.widget ?: "" ) ) ) {
			prc.widget = widgetsService.getWidget( rc.widget );

			event.setView( "admin/widgets/formDialog" );

		} else {
			prc.widgets = _getSortedAndTranslatedWidgets( rc.widgetCategories ?: "" );

			event.setView( "admin/widgets/browserDialog" );
		}
	}

	public void function saveConfigFormAction( event, rc, prc ) output=false {
		var widget               = rc.widget ?: "";
		var validationResult = "";
		var config           = {};

		if ( widgetsService.widgetHasConfigForm( widget ) ) {
			config = event.getCollectionForForm( widgetsService.getConfigFormForWidget( widget ) );
			structDelete( config, "widget" );
			structDelete( config, "configJson" );

			validationResult = widgetsService.validateWidgetConfig(
				  widgetId = widget
				, config         = config
			);

			if ( not validationResult.validated() ) {
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );

				config.validationResult = validationResult;

				setNextEvent( url=event.buildAdminLink( linkTo="widgets.dialog", querystring="widget=#widget#" ), persistStruct=config );
			}
		}

		setNextEvent( url=event.buildAdminLink( linkTo="widgets.dialog", querystring="widget=#widget#" ), persistStruct={ widgetConfigSaved = true, savedConfig=config } );
	}

	public void function renderWidgetPlaceholder( event, rc, prc ) output=false {
		var rendered = widgetsService.renderWidgetPlaceholder(
			  widgetId   = rc.widgetId ?: ""
			, configJson = rc.data     ?: ""
		);

		event.renderData( data=Trim( rendered ), type="HTML" );
	}

// private helpers
	private query function _getSortedAndTranslatedWidgets( required string categories ) output=false {
		// todo, cache this operation (per locale)
		var unsortedOrTranslated = widgetsService.getWidgets( categories=ListToArray( arguments.categories ) );
		var tempArray            = [];
		var activeSiteTemplate   = siteService.getActiveSiteTemplate();

		for( var id in unsortedOrTranslated ) {
			var widget = Duplicate( unsortedOrTranslated[ id ] );

			if ( widget.siteTemplates == "*" || ListFindNoCase( widget.siteTemplates, activeSiteTemplate ) ) {
				widget.title       = translateResource( uri=widget.title      , defaultValue=widget.title );
				widget.description = translateResource( uri=widget.description, defaultValue=widget.description );
				widget.icon        = translateResource( uri=widget.icon       , defaultValue="fa-magic" );

				tempArray.append( widget );
			}
		}

		tempArray.sort( function( widget1, widget2 ){
			return widget1.title == widget2.title ? 0 : ( widget1.title > widget2.title ? 1 : -1 );
		} );

		return arrayOfStructsToQuery( "id,title,description,icon", tempArray );
	}
}