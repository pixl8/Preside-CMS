component {
	property name="formbuilderService" inject="formbuilderService";

	private function index( event, rc, prc, args={} ) {
		return "<p>**Form builder form render not yet implemented**</p>";
	}

	private string function placeholder( event, rc, prc, args={} ) {
		var fbForm          = formbuilderService.getForm( args.form ?: "" );
		var translationArgs = [ fbForm.name ?: "unknown form" ];

		if ( Len( Trim( args.instanceid ?: "" ) ) ) {
			translationArgs[1] &= " (" & args.instanceid & ")";
		}

		return translateResource( uri="widgets.FormBuilderForm:placeholder", data=translationArgs );
	}
}