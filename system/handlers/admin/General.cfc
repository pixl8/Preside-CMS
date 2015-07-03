component {

	property name="updateManagerService" inject="updateManagerService";

// viewlets
	private string function footer( event, rc, prc, args={} ) {
		args.isGitClone     = updateManagerService.isGitClone();

		args.currentVersion = args.isGitClone ? updateManagerService.getGitBranch() : updateManagerService.getCurrentVersion();

		return renderView( view="/admin/general/footer", args=args );
	}
}