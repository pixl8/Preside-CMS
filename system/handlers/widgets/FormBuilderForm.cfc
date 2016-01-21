component {
	property name="formbuilderService" inject="formbuilderService";

	private function index( event, rc, prc, args={} ) {
		var formId = args.form   ?: "";
		var layout = args.layout ?: "";
		var rendered = "";

		if ( Len( Trim( formId ) ) ) {
			if ( !formbuilderService.isFormActive( formId ) ) {
				if ( !event.isAdminUser() ) {
					return "";
				}

				rendered = '<div class="alert alert-warning"><p><strong>' & translateResource( "formbuilder:inactive.form.admin.preview.warning") & '</strong></p></div>';
			}
			rendered &= formbuilderService.renderForm(
				  formId           = formId
				, layout           = layout
				, configuration    = args
				, validationResult = rc.validationResult ?: ""
			);
		}

		return rendered;
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