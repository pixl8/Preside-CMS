component {

	property name="permissionService" inject="permissionService";

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

	private struct function myAdminGroups( event, rc, prc, args={} ) {
		if ( !event.isAdminUser() ) {
			return { filter="1=0" };
		}

		var groups = permissionService.listUserGroups(
			  userId          = event.getAdminUserId()
			, includeCatchAll = false
		);

		return { filter = { id=groups } };
    }

    private struct function globalRulesEngineFilters( event, rc, prc, args={} ) {
    	return {
    		  filter = "filter_sharing_scope is null or filter_sharing_scope = :filter_sharing_scope"
    		, filterParams = { filter_sharing_scope="global" }
    	};
    }

}