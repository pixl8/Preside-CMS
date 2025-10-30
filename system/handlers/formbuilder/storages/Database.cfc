component {

	property name="formbuilderDraftStorageDatabaseTable" inject="coldbox:setting:formbuilder.drafts.storage.database.table";

	public struct function getTempData(
		  required string formId
		, required string storageKey
		,          string userId = getLoggedInUserId()
	) {
		var data = getPresideObject( formbuilderDraftStorageDatabaseTable ).selectData(
			  filter       = "id = :id and form = :form and submitted_by = :submitted_by"
			, filterParams = {
				  id           = { cfsqltype="cf_sql_varchar", 	value=arguments.storageKey }
				, form         = { cfsqltype="cf_sql_varchar", 	value=arguments.formId     }
				, submitted_by = { cfsqltype="cf_sql_varchar", 	value=arguments.userId     }
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
		, required string storageKey
		, required struct data
		,          string userId = getLoggedInUserId()
	) {
		var filter       = "id = :id and form = :form and submitted_by = :submitted_by";
		var filterParams = {
			  id           = { cfsqltype="cf_sql_varchar", 	value=arguments.storageKey }
			, form         = { cfsqltype="cf_sql_varchar", 	value=arguments.formId     }
			, submitted_by = { cfsqltype="cf_sql_varchar", 	value=arguments.userId     }
		};

		if ( getPresideObject( formbuilderDraftStorageDatabaseTable ).dataExists( filter=filter, filterParams=filterParams ) ) {
			getPresideObject( formbuilderDraftStorageDatabaseTable ).updateData(
				  filter       = filter
				, filterParams = filterParams
				, data         = {
					submitted_data = IsEmpty( arguments.data ) ? NullValue() : SerializeJson( arguments.data )
				  }
			 );

			return arguments.storageKey;
		} else {
			return getPresideObject( formbuilderDraftStorageDatabaseTable ).insertData( data={
				  form           = arguments.formId
				, submitted_by   = arguments.userId
				, submitted_data = IsEmpty( arguments.data ) ? NullValue() : SerializeJson( arguments.data )
			} );
		}
	}

	public void function clearTempData(
		  required string formId
		, required string storageKey
	) {
		getPresideObject( formbuilderDraftStorageDatabaseTable ).deleteData(
			  filter       = "id = :id and form = :form"
			, filterParams = {
				  id   = { cfsqltype="cf_sql_varchar", 	value=arguments.storageKey }
				, form = { cfsqltype="cf_sql_varchar", 	value=arguments.formId     }
			  }
		);
	}

}