component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineTimePeriodService" inject="rulesEngineTimePeriodService";
	property name="webflowInstanceService"       inject="webflowInstanceService";

	private boolean function isEnabled( event, rc, prc, args={} ) {
		return isFeatureEnabled( "webflow" );
	}

	private boolean function isUserDashboardWidget( event, rc, prc, args={} ) {
		return true;
	}

	private string function render( event, rc, prc, args={} ) {
		var webflowId  = args.config.webflow ?: "";
		var timePeriod = rulesEngineTimePeriodService.convertTimePeriodToDateRange( args.config.time_period ?: "" );

		if ( !Len( webflowId ) ) {
			return translateResource( uri="admin.admindashboards.widget.webflowJourneyChart:error.no.webflow" );
		}

		var wfConfig = getPresideObject( "webflow_configuration" ).selectData(
			  id           = webflowId
			, selectFields = [ "webflow_id", "instance_ref" ]
			, returntype   = "singleRecordStruct"
		);

		if ( !Len( wfConfig.webflow_id ?: "" ) ) {
			return translateResource( uri="admin.admindashboards.widget.webflowJourneyChart:error.no.webflow" );
		}

		var widgetTitle       = Trim( args.config.widget_title ?: "" );
		var transitionsConfig = webflowInstanceService.getWebflowTransitionsConfigForJourneyChart(
			  webflowId    = wfConfig.webflow_id
			, webflowRef   = wfConfig.instance_ref ?: ""
			, instanceRef  = args.config.instance  ?: ""
			, statuses     = ( args.config.type    ?: "current" ) == "current" ? ( args.config.current_statuses ?: "" ) : ( args.config.historical_statuses ?: "" )
			, isHistorical = ( args.config.type    ?: "current" ) == "historical"
			, startDate    = timePeriod.from       ?: NullValue()
			, endDate      = timePeriod.to         ?: NullValue()
		);

		if ( !ArrayLen( transitionsConfig.transitions ?: [] ) ) {
			return translateResource( uri="admin.admindashboards.widget.webflowJourneyChart:error.no.transitions" );
		}

		var chart = newChart( type="sankey", theme="adminDashboardWidgets" )
					.setId( "widget_#Hash( args.configInstanceId )#" )
					.setAspectRatio( 1.5 )
					.addDataset(
						  label   = widgetTitle
						, data    = transitionsConfig.transitions
						, options = {
							  size   = "max"
							, labels = transitionsConfig.labels ?: {}
						}
					);

		return chart.render();
	}

	private void function ajaxIncludes( event, rc, prc, args={} ) {
		event.include( "chartjs" )
			 .include( "chartjs-chart-sankey" );
	}

	private string function ajaxCallback( event, rc, prc, args={} ) {
		return "widget_#Hash( args.configInstanceId )#_init";
	}
}