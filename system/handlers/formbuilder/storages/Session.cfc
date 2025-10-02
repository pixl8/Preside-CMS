component {

	property name="sessionStorage" inject="SessionStorage";

	public struct function getTempData(
		  required string formId
		,          string submissionId = ""
	) {
		return sessionStorage.getVar( "temp_formbuilder_submission_#arguments.formId#", StructNew() );
	}

	public void function setTempData(
		  required string formId
		,          string submissionId = ""
		,          struct data         = {}
	) {
		sessionStorage.setVar( "temp_formbuilder_submission_#arguments.formId#", arguments.data );
	}

	public void function clearTempData(
		  required string formId
		,          string submissionId = ""
	) {
		sessionStorage.deleteVar( "temp_formbuilder_submission_#arguments.formId#" );
	}

}