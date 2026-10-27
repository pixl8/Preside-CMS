component {

	private boolean function isEnabled() {
		return true;
	}

	private void function run() {
		var dao        = getPresideObject( "my_extension_object" );
		var folderDao  = getPresideObject( "rules_engine_filter_folder" );
		var filterDao  = getPresideObject( "rules_engine_condition" );
		var objectName = "my_extension_object";
		var i          = 0;
		var folders    = {};

		if ( dao.dataExists( filter={ label="E2E Alpha 01" } ) ) {
			return;
		}

		for( i=1; i<=5; i++ ) {
			dao.insertData( {
				  label               = "E2E Alpha " & NumberFormat( i, "00" )
				, status              = "active"
				, category            = "widgets"
				, notes               = ( i == 1 ) ? "E2E-NOTES-ALPHA-01" : ""
				, sensitive_col       = ( i == 1 ) ? "E2E-SENSITIVE-ALPHA-01" : ""
				, other_sensitive_col = ( i == 1 ) ? "E2E-OTHER-SENSITIVE-ALPHA-01" : ""
			} );
		}
		for( i=1; i<=5; i++ ) {
			dao.insertData( {
				  label    = "E2E Beta " & NumberFormat( i, "00" )
				, status   = "draft"
				, category = "gadgets"
			} );
		}
		for( i=1; i<=12; i++ ) {
			dao.insertData( {
				  label    = "E2E Other " & NumberFormat( i, "00" )
				, status   = "active"
				, category = "misc"
			} );
		}

		folders[ "Alpha folder" ] = folderDao.insertData( {
			  label       = "Alpha folder"
			, object_name = objectName
		} );
		folders[ "Subscriptions" ] = folderDao.insertData( {
			  label       = "Subscriptions"
			, object_name = objectName
		} );

		filterDao.insertData( {
			  condition_name         = "Starred alphas"
			, filter_object          = objectName
			, expressions            = _labelContains( "E2E Alpha" )
			, is_favourite           = true
			, is_segmentation_filter = false
			, filter_sharing_scope   = "global"
		} );

		filterDao.insertData( {
			  condition_name           = "Professors"
			, filter_object            = objectName
			, expressions              = _labelContains( "E2E" )
			, is_favourite             = false
			, is_segmentation_filter   = true
			, segmentation_last_count  = 22
			, filter_sharing_scope     = "global"
		} );

		filterDao.insertData( {
			  condition_name         = "Foldered alphas"
			, filter_object          = objectName
			, expressions            = _labelContains( "E2E Alpha" )
			, is_favourite           = false
			, is_segmentation_filter = false
			, filter_folder          = folders[ "Alpha folder" ]
			, filter_sharing_scope   = "global"
		} );

		filterDao.insertData( {
			  condition_name         = "Active pro rata subscriptions"
			, filter_object          = objectName
			, expressions            = _labelContains( "E2E Beta" )
			, is_favourite           = false
			, is_segmentation_filter = false
			, filter_folder          = folders[ "Subscriptions" ]
			, filter_sharing_scope   = "global"
		} );

		filterDao.insertData( {
			  condition_name         = "Loose other filter"
			, filter_object          = objectName
			, expressions            = _labelContains( "E2E Other" )
			, is_favourite           = false
			, is_segmentation_filter = false
			, filter_sharing_scope   = "global"
		} );
	}

	private string function _labelContains( required string value ) {
		return SerializeJson( [ {
			  expression = "presideobject_stringmatches_my_extension_object.label"
			, fields     = { value=arguments.value, _stringOperator="contains" }
		} ] );
	}

}
