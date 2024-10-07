<cfscript> 
	reporter  = url.reporter  ?: "simple";
	scope     = url.scope     ?: "full";
	directory = url.directory ?: "";
	testbox   = new testbox.system.TestBox( options={ coverage={ enabled=true } }, directory={
		  recurse  = true
		, mapping  = Len( directory ) ? "unit.api.#directory#" : "unit"
		, filter   = function( required path ){
			if ( scope=="quick" ) {
				var excludes = [
					  "presideObjects/PresideObjectServiceTest"
					, "security/CsrfProtectionServiceTest"
					, "admin/LoginServiceTest"
					, "admin/AuditServiceTest"
					, "sitetree/SiteServiceTest"
				];
				for( var exclude in excludes ) {
					if ( ReFindNoCase( listLast( exclude, "/" ), path ) ) {
						return false;
					}
				}
				return true;
			}
			return true;
		}
	} );

	results = Trim( testbox.run( reporter=reporter ) );
	content reset=true; echo( results ); abort;
</cfscript>