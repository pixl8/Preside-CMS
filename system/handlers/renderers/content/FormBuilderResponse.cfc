/**
 * @feature formbuilder
 */
component {
	property name="formBuilderService" inject="formBuilderService";

	private string function default(event, rc, prc, args={} ){
		return formBuilderService.renderV2QuestionResponses( args.formId, args.submissionId, args.questionId, args.itemType );
	}
}