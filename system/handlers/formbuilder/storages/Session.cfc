component {

	property name="sessionStorage" inject="SessionStorage";

	public struct function getTempData(
		required string formId
	) {
		return sessionStorage.getVar( "temp_formbuilder_submission_#arguments.formId#", StructNew() );
	}

	public void function setTempData(
		  required string formId
		, required struct data
	) {
		sessionStorage.setVar( "temp_formbuilder_submission_#arguments.formId#", arguments.data );
	}

	public void function clearTempData(
		required string formId
	) {
		sessionStorage.deleteVar( "temp_formbuilder_submission_#arguments.formId#" );
	}

}