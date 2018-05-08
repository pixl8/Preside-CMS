<cffunction name="isBot" returntype="boolean" access="public">
	<cfscript>
		var userAgent = LCase( cgi.http_user_agent );

		return    !Len( userAgent )
				|| REFind( "bot\b"              , userAgent )
				|| REFind( "\brss"              , userAgent )
				|| Find( "slurp"                , userAgent )
				|| Find( "mediapartners-google" , userAgent )
				|| Find( "zyborg"               , userAgent )
				|| Find( "emonitor"             , userAgent )
				|| Find( "jeeves"               , userAgent )
				|| Find( "sbider"               , userAgent )
				|| Find( "findlinks"            , userAgent )
				|| Find( "yahooseeker"          , userAgent )
				|| Find( "mmcrawler"            , userAgent )
				|| Find( "jbrowser"             , userAgent )
				|| Find( "java"                 , userAgent )
				|| Find( "pmafind"              , userAgent )
				|| Find( "blogbeat"             , userAgent )
				|| Find( "converacrawler"       , userAgent )
				|| Find( "ocelli"               , userAgent )
				|| Find( "labhoo"               , userAgent )
				|| Find( "validator"            , userAgent )
				|| Find( "sproose"              , userAgent )
				|| Find( "ia_archiver"          , userAgent )
				|| Find( "larbin"               , userAgent )
				|| Find( "psycheclone"          , userAgent )
				|| Find( "arachmo"              , userAgent );
	</cfscript>
</cffunction>