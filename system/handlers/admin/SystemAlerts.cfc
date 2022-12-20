component extends="preside.system.base.AdminHandler" {

	property name="systemAlertsService" inject="systemAlertsService";
	property name="sessionStorage"      inject="sessionStorage";
	property name="messageBox"          inject="messagebox@cbmessagebox";

// VIEWLETS
	private string function systemAlertsMenuItem( event, rc, prc, args={} ) {
		args.alertCounts = systemAlertsService.getAlertCounts();
		args.levels      = systemAlertsService.getAlertLevels();

		if ( val( args.alertCounts.total ?: "" ) == 0 ) {
			return "";
		}

		return renderView( view="/admin/systemAlerts/systemAlertsMenuItem", args=args );
	}

	private any function runCheckInBackgroundThread( event, rc, prc, args={} ) {
		var type      = args.type      ?: "";
		var reference = args.reference ?: "";

		systemAlertsService.runCheck( type=type, reference=reference, async=false );
	}

	private any function displayCriticalAlerts( event, rc, prc, args={} ) {
		var alertsShown    = sessionStorage.getVar( name="displayedCriticalAlerts", default=[] );
		var criticalAlerts = systemAlertsService.getCriticalAlerts( ignore=alertsShown );
		var alerts         = [];
		var maximumToShow  = 3;
		var showMore       = criticalAlerts.recordCount > maximumToShow;
		var link           = "";
		var title          = "";

		for( var alert in criticalAlerts ) {
			if ( criticalAlerts.currentRow > maximumToShow || criticalAlerts.currentRow == maximumToShow && showMore ) {
				var remaining = ( criticalAlerts.recordCount - maximumToShow ) + 1;
				    link      = event.buildAdminLink( objectName="system_alert" );
				ArrayAppend( alerts, translateResource( uri="cms:systemAlerts.gritter.moreAlerts", data=[ remaining, link ] ) );
				break;
			}
			link  = event.buildAdminLink( objectName="system_alert", recordId=alert.id );
			title = renderContent( renderer="SystemAlertType", data=alert.type)
			ArrayAppend( alerts, translateResource( uri="cms:systemAlerts.gritter.singleAlert", data=[ title, link ] ) );
		}

		if ( ArrayLen( alerts ) ) {
			var viewletArgs = {
				  position = getSetting( "adminNotificationsPosition" )
				, title    = translateResource( "cms:systemAlerts.gritter.title" )
				, alerts   = alerts
			};
			var js = renderView( view="/admin/systemAlerts/criticalAlerts", args=viewletArgs );
			event.includeInlineJs( js );

			ArrayAppend( alertsShown, ValueArray( criticalAlerts, "id" ), true );
			sessionStorage.setVar( name="displayedCriticalAlerts", value=alertsShown );
		}

		return "";
	}

}