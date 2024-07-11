/**
 * @feature admin
 */
component {

	property name="permissionsCache" inject="cachebox:PermissionsCache";

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="usermanager.viewGroup", queryString="id=#( args.recordId ?: "" )#" );
	}

	private void function postEditRecordAction( event, rc, prc, args={} ) {
		permissionsCache.clearAll();
	}

	private void function postAddRecordAction( event, rc, prc, args={} ) {
		permissionsCache.clearAll();
	}

}