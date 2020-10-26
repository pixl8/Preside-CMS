component {

	private struct function formbuilderV1Form( event, rc, prc, args={} ) {
		return {
			  filter       = "formbuilder_form.uses_global_questions is null or formbuilder_form.uses_global_questions = :formbuilder_form.uses_global_questions"
			, filterParams = { "formbuilder_form.uses_global_questions"=false }
		};
	}

	private struct function formbuilderSingleChoiceFields( event, rc, prc, args={} ) {
		return {
			filter = "formbuilder_question.item_type='radio' or ( formbuilder_question.item_type='select' and formbuilder_question.item_type_config not like '%""multiple"":""1""%' )"
		};
	}

	private struct function formbuilderMultiChoiceFields( event, rc, prc, args={} ) {
		return {
			filter = "formbuilder_question.item_type='checkboxList' or ( formbuilder_question.item_type='select' and formbuilder_question.item_type_config like '%""multiple"":""1""%' )"
		};
	}

}