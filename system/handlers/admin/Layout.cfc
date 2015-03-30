component {

	property name="maintenanceModeService" inject="maintenanceModeService";

	private string function siteAlerts( event, rc, prc, args={} ) {
		args.inMaintenanceMode = maintenanceModeService.isMaintenanceModeActive();

		return renderView( view="/admin/layout/siteAlerts", args=args );
	}
}