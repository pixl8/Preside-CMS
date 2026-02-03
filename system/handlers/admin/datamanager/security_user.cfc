/**
 * @feature admin
 */
component {

	property name="permissionsCache" inject="cachebox:PermissionsCache";
	property name="loginService"     inject="LoginService";

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="usermanager.viewUser", queryString="id=#( args.recordId ?: "" )#" );
	}

	private void function postEditRecordAction( event, rc, prc, args={} ) {
		permissionsCache.clearAll();

		if ( isTrue( rc.resend_welcome ?: "" ) && !isEmptyString( rc.id ?: "" ) ) {
			loginService.sendWelcomeEmail( rc.id, event.getAdminUserDetails().known_as, rc.welcome_message ?: "" );
		}
	}

}