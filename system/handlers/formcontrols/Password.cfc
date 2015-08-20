component output=false {
	property name="passwordPolicyService" inject="passwordPolicyService";

	private string function index( event, rc, prc, args={} ) {
		if ( Len( Trim( args.passwordPolicyContext ?: "" ) ) ) {
			args.passwordPolicy = passwordPolicyService.getPolicy( args.passwordPolicyContext );
			args.policyMessage  = renderContent( renderer="richeditor", data=args.passwordPolicy.message ?: "" );
		}

		return renderView( view="/formcontrols/password/index", args=args );
	}
}