component {

	private string function index( event, rc, prc, args={} ) {
		if ( Len( Trim( args.passwordPolicyContext ?: "" ) ) ) {
			event.include( "/js/admin/specific/passwordscore/" )
			     .include( "/css/admin/specific/passwordscore/" )
			     .includeData( { passwordScoreCheckerUrl=event.buildLink( linkTo="passwordStrengthReport" ) } );;
		}

		return renderView( view="/formcontrols/password/index", args=args );
	}

	private string function admin( event, rc, prc, args={} ) {
		if ( Len( Trim( args.passwordPolicyContext ?: "" ) ) ) {
			event.include( "/js/admin/specific/passwordscore/" )
			     .include( "/css/admin/specific/passwordscore/" )
			     .includeData( { passwordScoreCheckerUrl=event.buildLink( linkTo="passwordStrengthReport" ) } );;
		}

		return renderView( view="/formcontrols/password/admin", args=args );
	}

}