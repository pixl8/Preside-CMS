<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="beforeTests" access="public" returntype="any" output="false">
		<cfscript>
			_clearRecentPresideServiceFetch()
			_emptyDatabase();
			_dbSync();
			_wipeTestData();
			_setupTestData();
		</cfscript>
	</cffunction>

	<cffunction name="afterTests" access="public" returntype="any" output="false">
		<cfscript>
			_wipeTestData();
		</cfscript>
	</cffunction>

	<cffunction name="setup" access="public" returntype="any" output="false">
		<cfscript>
			_deleteData( objectName="audit_log", forceDeleteAll=true );
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="test01_log_shouldAddRecordToAuditLogTable" returntype="void">
		<cfscript>
			var auditService = _getAuditService();
			var records = "";
			var args    = [{
				  detail    = { test="something happened" }
				, action    = "happened1"
				, type      = "happening"
				, userId    = testUsers[3].id
			},{
				  detail    = { test="something else happened" }
				, action    = "happened2"
				, type      = "happening"
				, userId    = testUsers[5].id
			}];

			auditService.log( argumentCollection = args[1] );
			auditService.log( argumentCollection = args[2] );

			records = _selectData( objectName = "audit_log", orderby="action" );

			super.assertEquals( 2, records.recordCount, "Expected two records to have been created. #records.recordCount# was reported instead." );

			for( var i = 1; i lte 2; i++ ){
				super.assertEquals( SerializeJson( args[i].detail ), records.detail[i]     );
				super.assertEquals( args[i].action                 , records.action[i]     );
				super.assertEquals( args[i].type                   , records.type[i]       );
				super.assertEquals( args[i].userId                 , records.user[i]       );
				super.assertEquals( cgi.http_user_agent            , records.user_agent[i] );
				super.assertEquals( cgi.remote_addr                , records.user_ip[i]    );
				super.assertEquals( cgi.request_url                , records.uri[i]        );
			}
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_getAuditService" access="private" returntype="any" output="false">
		<cfreturn new preside.system.services.admin.AuditService( dao=_getPresideObjectService().getObject( "audit_log" ) ) />
	</cffunction>

	<cffunction name="_wipeTestData" access="private" returntype="void" output="false">
		<cfscript>
			_deleteData( objectName="audit_log"    , forceDeleteAll=true );
			_deleteData( objectName="security_user", forceDeleteAll=true );
		</cfscript>
	</cffunction>

	<cffunction name="_setupTestData" access="private" returntype="void" output="false">
		<cfscript>
			variables.testUsers = [
				  { loginId="fred"    , pw="some%$p45%word" , name="Big Daddy"   , email="test1@test.com", id="" }
				, { loginId="james"   , pw="aN0THERP4$$word", name="007"         , email="test2@test.com", id="" }
				, { loginId="boris"   , pw="j0ns0n"         , name="Bendy Boris" , email="test3@test.com", id="" }
				, { loginId="pixl8"   , pw="1nter4ct!ve"    , name="Pixl8"       , email="test4@test.com", id="" }
				, { loginId="mandy"   , pw="sdfjlsdf84£rjs" , name="Patinkin"    , email="test5@test.com", id="" }
				, { loginId="sysadmin", pw="ajdlfjasfas&&^" , name="System Admin", email="test6@test.com", id="" }
			];
			for( var user in testUsers ){
				user.id = _insertData( objectName="security_user", data={ known_as=user.name, login_id=user.loginId, password=_bCryptPassword( user.pw ), email_address=user.email } );
			}
		</cfscript>
	</cffunction>
</cfcomponent>