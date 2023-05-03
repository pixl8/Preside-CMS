component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		describe( "auto group by", function(){
			it( "should only group by id when id field is present and DB adapter supports it", function(){
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

	}

}