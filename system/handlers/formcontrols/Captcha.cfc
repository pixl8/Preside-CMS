component {

	private function index( event, rc, prc, args={} ) {
		args.siteKey = getSystemSetting( "recaptcha", "site_key" );

		if ( args.siteKey.isEmpty() ) {
			return "";
		}

		return renderView( view="formcontrols/captcha/index", args=args );
	}

}
