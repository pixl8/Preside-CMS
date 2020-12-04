/**
 * @singleton      true
 * @presideService true
 */
component {

	public any function init() {
		return this;
	}

	public boolean function questionIsInUse( required string questionId ) {
		var hasResponse = $getPresideObjectService().dataExists(
			  objectName = "formbuilder_question_response"
			, filter     = { question=arguments.questionId }
		);

		var useInForm = $getPresideObjectService().dataExists(
			  objectName = "formbuilder_formitem"
			, filter     = { question=arguments.questionId }
		);

		return hasResponse || useInForm;
	}
}