<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="test01_checkpw_shouldReturnFalseForInvalidPassword" returntype="void">
		<cfscript>
			var bCrypt       = _getService();
			var realPassword = "some__join__St0ngisHpassword";
			var encrypted    = bCrypt.hashPw( realPassword );

			super.assertFalse( bCrypt.checkPw( "bad password", encrypted ) );

		</cfscript>
	</cffunction>

	<cffunction name="test02_checkpw_shouldReturnTrueForValidPassword" returntype="void">
		<cfscript>
			var bCrypt       = _getService();
			var realPassword = "some__join__St0ngisHpassword";
			var encrypted    = bCrypt.hashPw( realPassword );

			super.assert( bCrypt.checkPw( realPassword, encrypted ) );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_getService" access="private" returntype="any" output="false">
		<cfreturn _getBCrypt() />
	</cffunction>

</cfcomponent>