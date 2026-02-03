/**
 * @feature admin
 */
component {

	private struct function prepareParameters( event, rc, prc, args={} ) {
		return {
			  site_url       = event.getBaseUrl()
			, site_admin_url = event.getBaseUrl() & event.getAdminPath()
		};
	}

	private struct function getPreviewParameters( event, rc, prc, args={} ) {
		return {
			  site_url       = event.getBaseUrl()
			, site_admin_url = event.getBaseUrl() & event.getAdminPath()
		};
	}

	private string function defaultSubject() {
		return "Two factor authentication reset";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/resetTwoFactorAuthentication/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/resetTwoFactorAuthentication/defaultTextBody" );
	}

}