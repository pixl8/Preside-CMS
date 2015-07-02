component {

	property name="updateManagerService" inject="updateManagerService";

// viewlets
	private string function footer( event, rc, prc, args={} ) {
		args.currentVersion = updateManagerService.getCurrentVersion();

		return renderView( view="/admin/general/footer", args=args );
	}
}