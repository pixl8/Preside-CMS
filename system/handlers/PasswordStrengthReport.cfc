/**
 * @feature admin or cms
 */
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
				, message     = ""
			}, type="json" );
		} else {
			var score     = passwordStrengthAnalyzer.calculatePasswordStrength( rc.password ?: "" );
			var scoreName = passwordPolicyService.getStrengthNameForScore( score );
			var outputMsg = "";

			if ( len( trim( rc.context ?: "" ) ) ) {
				var messages = passwordPolicyService.getDetailPolicyMessages( context=rc.context, password=rc.password );

				if ( !isEmpty( messages ) ) {
					outputMsg    = "<ul>";
					for ( var message in messages ) {
						outputMsg &= "<li>#translateResource( "cms:passwordpolicy.message.prefix" )# #message#</li>";
					}
					outputMsg &= "</ul>";
				}
			}

			event.renderData( data={
				  score       = score
				, name        = scoreName
				, title       = translateResource( "cms:password.strength.#scoreName#.title" )
				, description = translateResource( "cms:password.strength.#scoreName#.description" )
				, message     = outputMsg
			}, type="json" );
		}
	}

	public string function renderPolicyMessage( event, rc, prc, args={} ) {
		var policyContext   = args.context ?: "website";
		var policyDetail    = passwordPolicyService.getPolicy( context=policyContext );
		args.detailMessages = passwordPolicyService.getDetailPolicyMessages( context=policyContext );
		args.customMessage  = policyDetail.message ?: "";

		return renderView ( view="/general/_passwordPolicyMessage", args=args );
	}
}