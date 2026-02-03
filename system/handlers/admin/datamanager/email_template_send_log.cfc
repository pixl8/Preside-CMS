/**
 * @feature admin and emailCenter
 */
component {

	private string function buildListingLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo="emailcenter.logs" );
	}

	private string function listingViewlet( event, rc, prc, args={} ) {
		event.include( "/js/admin/specific/htmliframepreview/" );
		event.include( "/css/admin/specific/htmliframepreview/" );

		return runEvent(
			  event          = "admin.DataManager._objectListingViewlet"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=arguments.args }
		);
	}

}
