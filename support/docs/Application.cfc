component {
	this.name = "presideDocumentationBuilder-" & Hash( GetCurrentTemplatePath() );

	this.cwd = GetDirectoryFromPath( GetCurrentTemplatePath() )

	this.mappings[ "/api"      ] = this.cwd & "api";
	this.mappings[ "/builders" ] = this.cwd & "builders";
	this.mappings[ "/docs"     ] = this.cwd & "docs";
	this.mappings[ "/import"   ] = this.cwd & "import";
	this.mappings[ "/builds"   ] = this.cwd & "builds";
	this.mappings[ "/preside"  ] = ExpandPath( this.cwd & "../../" );
        this.mappings[ "/coldbox"  ] = ExpandPath( this.cwd & "../../system/externals/coldbox-standalone-3.8.2/coldbox" );

	public boolean function onRequest( required string requestedTemplate ) output=true {
		include template=arguments.requestedTemplate;

		return true;
	}
}
