component {

	private function index( event, rc, prc, args={} ) {
		args.siteKey = recaptchaSiteKey();

		if ( args.siteKey.isEmpty() ) {
			return "";
		}

		return renderView( view="formcontrols/captcha/index", args=args );
	}

}
