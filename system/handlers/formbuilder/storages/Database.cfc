component {

	public struct function getTempData(
		  required string formId
		, required string id
	) {
		var data = getPresideObject( "formbuilder_formsubmission_draft" ).selectData(
			  filter       = "id = :id and form = :form"
			, filterParams = {
				  id   = { cfsqltype="cf_sql_varchar", 	value=arguments.id     }
				, form = { cfsqltype="cf_sql_varchar", 	value=arguments.formId }
			  }
			, selectFields = [ "submitted_data" ]
			, returnType   = "singleValue"
			, columnKey    = "submitted_data"
			, useCache     = false
		);

		return IsEmpty( data ) ? StructNew() : DeserializeJson( data );
	}

	public string function setTempData(
		  required string formId
		, required string id
		, required struct data
	) {
		var filter       = "id = :id and form = :form";
		var filterParams = {
			  id   = { cfsqltype="cf_sql_varchar", 	value=arguments.id }
			, form = { cfsqltype="cf_sql_varchar", 	value=arguments.formId }
		};

		if ( getPresideObject( "formbuilder_formsubmission_draft" ).dataExists( filter=filter, filterParams=filterParams ) ) {
			getPresideObject( "formbuilder_formsubmission_draft" ).updateData(
				  filter       = filter
				, filterParams = filterParams
				, data         = {
					submitted_data = IsEmpty( arguments.data ) ? NullValue() : SerializeJson( arguments.data )
				  }
			 );

			return arguments.id;
		} else {
			return getPresideObject( "formbuilder_formsubmission_draft" ).insertData( data={
				  form           = arguments.formId
				, submitted_by   = getLoggedInUserId()
				, submitted_data = IsEmpty( arguments.data ) ? NullValue() : SerializeJson( arguments.data )
			} );
		}
	}

	public void function clearTempData(
		  required string formId
		, required string id
	) {
		getPresideObject( "formbuilder_formsubmission_draft" ).deleteData(
			  filter       = "id = :id and form = :form"
			, filterParams = {
				  id   = { cfsqltype="cf_sql_varchar", 	value=arguments.id     }
				, form = { cfsqltype="cf_sql_varchar", 	value=arguments.formId }
			  }
		);
	}

}