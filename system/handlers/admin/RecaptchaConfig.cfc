component extends="preside.system.base.AdminHandler" {

	private void function includeJs() {
		event.include( "recaptcha-js" );
	}

	private string function validationEndpoint() {
		return "https://www.recaptcha.net/recaptcha/api/siteverify";
	}

	private string function siteKey() {
		return getSystemSetting( "recaptcha", "site_key" );
	}

	private string function secretKey() {
		return getSystemSetting( "recaptcha", "secret_key" );
	}

}