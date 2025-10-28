/**
 * @feature webflow
 */
component extends="preside.system.base.AdminHandler" {

	public void function submitAction() {
		// wrapping this here to add admin security layer from base admin handler
		// i.e. at least check we are logged in before allowing the submission
		runEvent( "webflow.default.submitAction" );
	}

}