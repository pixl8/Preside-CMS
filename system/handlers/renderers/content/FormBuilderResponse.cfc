component  {

	property name="formBuilderService" inject="formBuilderService";


	private string function default(event, rc, prc, args={} ){
		var rendered = formBuilderService.renderV2QuestionResponses( args.formId, args.submissionId, args.questionId, args.itemType ) ;
		return rendered;
	}
}