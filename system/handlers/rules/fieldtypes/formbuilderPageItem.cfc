component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var formItemId = config.formbuilderItem ?: "";
		var formItem   = formBuilderService.getFormItem( id=formItemId );

		if ( isEmptyString( formItem.questionId ?: "" ) ) {
			return "";
		}

		return renderLabel( objectName="formbuilder_question", recordId=formItem.questionId );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var formId     = config.formbuilderForm ?: "";
		var pageId     = config.formbuilderPage ?: "";
		var pageNumber = 0;

		var values = [];
		var labels = [];

		var formItems = getPresideObject( "formbuilder_formitem" ).selectData(
			  selectFields = formBuilderService.getFormItemDefaultFields( id=formId, withPageNumber=true )
			, filter       = { form=formId }
			, orderBy      = "sort_order"
		);

		var filteredFormItems = [];
		for ( var formItem in formItems ) {
			if ( formItem.id == pageId ) {
				pageNumber = formItem.page_number;
			} else if ( formItem.page_number == pageNumber ) {
				ArrayAppend( values, formItem.id );
				ArrayAppend( labels, renderLabel( objectName="formbuilder_question", recordId=formItem.question ) );
			}
		}

		StructDelete( rc, "value" );

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "select"
			, values             = values
			, labels             = labels
			, label              = translateResource( "rules.fieldTypes.formbuilderPageItem:label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, resultTemplate     = "{{{text}}}"
			, selectedTemplate   = "{{{text}}}"
		);
	}

}