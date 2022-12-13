component extends="preside.system.base.AdminHandler" {

	property name="systemAlertsService" inject="systemAlertsService";

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

}