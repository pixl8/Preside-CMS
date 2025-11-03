/**
 * @feature webflow
 */
component extends="preside.system.base.AdminHandler" {

	/**
	 * @cacheable false
	 *
	 */
	public string function ajaxLayout(  event, rc, prc, args={}  ) {
		event.preventPageCache();
		event.setLayout( "adminModalDialog" );

		prc.content = renderViewlet( event="webflow.default.ajaxLayout", args=args );
	}

	public void function submitAction() {
		// wrapping this here to add admin security layer from base admin handler
		// i.e. at least check we are logged in before allowing the submission
		runEvent( "webflow.default.submitAction" );
	}

	public void function submitAjaxAction() {
		runEvent( "webflow.default.submitAjaxAction" );
	}
}