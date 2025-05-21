component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		if ( isEmptyString( arguments.value ) ) {
			return translateResource( uri="rules.fieldTypes.formbuilderPage:option.any.label" );
		}

		var formId = config.formbuilderForm ?: "";

		if ( isEmptyString( formId ) ) {
			var formItem = formBuilderService.getFormItem( id=arguments.value );

			formId = formId.form ?: "";
		}

		var page   = formBuilderService.getPage( formId=formId, formItemId=arguments.value );
		var config = IsJSON( page.configuration ?: "" ) ? DeserializeJSON( page.configuration ) : page.configuration;

		return _renderLabel( config.label ?: "", page.page_number );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var formId = config.formbuilderForm ?: "";
		var values = [];
		var labels = [];

		if ( !isEmptyString( formId ) ) {
			var pages = formBuilderService.getPages( formId=formId );

			for ( var page in pages ) {
				if ( !isEmptyString( page.page_number ?: "" ) ) {
					var config = IsJSON( page.configuration ?: "" ) ? DeserializeJSON( page.configuration ) : page.configuration;

					ArrayAppend( values, page.id );
					ArrayAppend( labels, _renderLabel( config.label ?: "", page.page_number ) ) ;
				}
			}
		}

		StructDelete( rc, "value" );

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "select"
			, values             = values
			, labels             = labels
			, label              = translateResource( "rules.fieldTypes.formbuilderPage:label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
		);
	}

	private string function _renderLabel( required string label, required string pageNumber ) {
		if ( isEmptyString( arguments.label ) ) {
			arguments.label = translateResource( uri="rules.fieldTypes.formbuilderPage:option.untitled.label" );
		}

		return translateResource( uri="rules.fieldTypes.formbuilderPage:option.page.label", data=[ arguments.pageNumber, arguments.label ] )
	}

}