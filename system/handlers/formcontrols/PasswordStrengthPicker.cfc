component output=false {
	property name="passwordPolicyService" inject="passwordPolicyService";

	private string function index( event, rc, prc, args={} ) {
		args.strengths = passwordPolicyService.listStrengths();

		return renderView( view="/formcontrols/passwordStrengthPicker/index", args=args );
	}
}