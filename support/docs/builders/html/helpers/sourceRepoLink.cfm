<cfscript>
	string function getSourceLink( required string path ) {
		var sourceBase = new api.build.BuildProperties().getEditSourceLink();
		return Replace( sourceBase, "{path}", arguments.path );
	}
</cfscript>