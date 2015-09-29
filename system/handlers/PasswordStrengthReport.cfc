component {

	property name="passwordPolicyService"    inject="passwordPolicyService";
	property name="passwordStrengthAnalyzer" inject="passwordStrengthAnalyzer";

	function index( event, rc, prc ) {
		if ( !Len( Trim( rc.password ?: "" ) ) ) {
			event.renderData( data={
				  score       = 0
				, name        = ""
				, title       = ""
				, description = ""
			}, type="json" );
		} else {
			var score     = passwordStrengthAnalyzer.calculatePasswordStrength( rc.password ?: "" );
			var scoreName = passwordPolicyService.getStrengthNameForScore( score );

			event.renderData( data={
				  score       = score
				, name        = scoreName
				, title       = translateResource( "cms:password.strength.#scoreName#.title" )
				, description = translateResource( "cms:password.strength.#scoreName#.description" )
			}, type="json" );
		}
	}

}