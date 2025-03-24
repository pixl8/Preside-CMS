/**
 * @expressionCategory formbuilder
 * @expressionContexts webrequest
 * @feature            rulesEngine
 */
component {
	
	/**
	 * @formbuilderForm.fieldType    object
	 * @formbuilderForm.object       formbuilder_form
	 * @formbuilderForm.multiple     false
	 * @formbuilderForm.labelUriRoot rules.FormbuilderFormPageFieldMatches:
	 *
	 * @formbuilderPage.fieldType    formbuilderPage
	 *
	 * @formbuilderItem.fieldType    formbuilderPageItem
	 *
	 * @formbuilderAnswer.fieldType  formbuilderPageAnswer
	 */
	private boolean function evaluateExpression(
		  required string formbuilderForm
		, required string formbuilderPage
		, required string formbuilderItem
		, required string formbuilderAnswer
	) {
		return true;
	}

}
