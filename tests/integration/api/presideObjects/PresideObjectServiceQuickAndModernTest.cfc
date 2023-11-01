component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		describe( "auto group by", function(){
			it( title="should only group by id when id field is present and DB adapter supports it", body=function(){
				var poService = _getPresideObjectService();
				var idFieldGuises = [ "id", "`id`", "`email_template`.id", "`email_template`.`id`", "email_template.id", "email_template.`id`" ];

				for( var idField in idFieldGuises ) {
					var sqlAndParams = poService.selectData(
						  objectName          = "email_template"
						, selectFields        = [ idField, "name", "sent_count" ]
						, orderBy             = "name"
						, autoGroupBy         = true
						, getSqlAndParamsOnly = true
					);

					expect( sqlAndParams.sql contains "group by `email_template`.`id` order by" or sqlAndParams.sql contains "group by #idField# order by").toBeTrue();
				}
			}, skip=function(){
				return !_getDbAdapter( "preside_test_suite" ).supportsGroupBySingleField();
			} );

			it( "should group by all non aggregate fields when id field is NOT present but DB adapter does support single group by field", function(){
				var poService = _getPresideObjectService();
				var sqlAndParams = poService.selectData(
					  objectName          = "email_template"
					, selectFields        = [ "name", "recipient_type", "subject", "sent_count" ]
					, orderBy             = "name"
					, autoGroupBy         = true
					, getSqlAndParamsOnly = true
				);
				expect( sqlAndParams.sql contains "group by `email_template`.`name`, `email_template`.`recipient_type`, `email_template`.`subject` order by" ).toBeTrue();
			} );
		} );

		describe( "simplifySelectFieldsForRecordCount()", function(){
			it( "should strip out all aggregate select fields that would be grouped by autogroupby", function(){
				var poService = _getPresideObjectService();
				var selectFields = [ "id", "name", "count( distinct send_logs.id ) as send_log_count", "group_concat( send_logs.id ) as logIds", "sum( send_logs.click_count ) as total_clicks" ]

				expect( poService.simplifySelectFieldsForRecordCount(
					  objectName   = "email_template"
					, autoGroupBy  = true
					, selectFields = selectFields
				) ).toBe( [ "id", "name"] );

			} );

			it( "should do nothing when autogroupby is false", function(){
				var poService = _getPresideObjectService();
				var selectFields = [ "id", "name", "datecreated", "count( distinct send_logs.id ) as send_log_count", "group_concat( send_logs.id ) as logIds", "sum( send_logs.click_count ) as total_clicks" ]

				expect( poService.simplifySelectFieldsForRecordCount(
					  objectName   = "email_template"
					, selectFields = selectFields
					, autoGroupBy = false
				) ).toBe( selectFields );
			} );
		} );

	}

}