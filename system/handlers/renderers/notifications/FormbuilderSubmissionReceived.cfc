/**
 * @feature formbuilder
 */
component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function datatable( event, rc, prc, args={} ) {
		var formName = _getFormName( submissionId=( args.id ?: "" ) );

		if ( !isEmptyString( formName ) ) {
			return translateResource( uri="notifications.FormbuilderSubmissionReceived:datatable.title" , data=[ formName ] );
		}

		return "";
	}

	private string function full( event, rc, prc, args={} ) {
		var formName = _getFormName( submissionId=( args.id ?: "" ), includeLink=true );

		if ( !isEmptyString( formName ) ) {
			return renderView(
				  view = "/renderers/notifications/FormbuilderSubmissionReceived/full"
				, args = {
					formName = formName
				  }
			);
		}

		return "";
	}

	private string function _getFormName(
		  required string  submissionId
		,          boolean includeLink = false
	) {
		var submission = formBuilderService.getSubmission(
			  submissionId = arguments.submissionId
			, selectFields = [
				  "form.id   as form_id"
				, "form.name as form_name"
			  ]
		);

		var formName = Trim( submission.form_name ?: "" );

		if ( !isEmptyString( formName ) ) {
			if ( includeLink ) {
				formName = '<a href="#getRequestContext().buildAdminLink( linkTo="formbuilder.submissions", queryString="id=#submission.form_id#" )#">#formName#</a>';
			}
		}

		return formName;
	}

}