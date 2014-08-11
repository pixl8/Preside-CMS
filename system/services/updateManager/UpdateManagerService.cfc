/**
 * The Update Manager Service provides the APIs
 * for managing the installed version of core Preside
 * for your application.
 *
 */
component output=false autodoc=true displayName="Update manager service" {

// constructor
	/**
	 * @repositoryUrl.inject coldbox:setting:updateRepositoryUrl
	 *
	 */
	public any function init( required string repositoryUrl, string presidePath="/preside" ) output=false {
		_setRepositoryUrl( arguments.repositoryUrl );
		_setPresidePath( arguments.presidePath );

		return this;
	}

// public methods
	public string function getCurrentVersion() output=false {
		var versionFile = ListAppend( _getPresidePath(), "version.json", "/" );
		var versionInfo = "";

		if ( !FileExists( versionFile ) ) {
			return "unknown";
		}

		try {
			versionInfo = DeSerializeJson( FileRead( versionFile ) );
		} catch ( any e ) {
			return "unknown";
		}

		return versionInfo.version ?: "unknown";
	}

	public array function listVersions( required string branch ) output=false {
		var s3Listing         = _fetchS3BucketListing();
		var branchPath        = _getRemoteBranchPath( arguments.branch );
		var xPath             = "/:ListBucketResult/:Contents/:Key[starts-with(.,'#branchPath#')]/text()";
		var versionFiles      = XmlSearch( s3Listing, xPath );
		var jsonAndZipMatches = {};
		var versions          = [];

		for( var versionFilePath in versionFiles ) {
			versionFilePath = versionFilePath.xmlText;

			if ( ReFindNoCase( "\.(zip|json)$", versionFilePath ) ) {
				var fileKey  = ReReplace( versionFilePath, "^(.*)\.(zip|json)$", "\1" );
				var fileType = ReReplace( versionFilePath, "^(.*)\.(zip|json)$", "\2" );

				jsonAndZipMatches[ fileKey ][ fileType ] = true;
			}
		}

		for( var fileKey in jsonAndZipMatches ) {
			versions.append( _fetchVersionInfo( fileKey & ".json" ).version );
		}

		return versions;
	}

// private helpers
	private xml function _fetchS3BucketListing() output=false {
		return XmlParse( _getRepositoryUrl() );
	}

	private struct function _fetchVersionInfo( required string versionFilePath ) ouptut=false {
		var result = "";
		var versionFileUrl = ListAppend( _getRepositoryUrl(), arguments.versionFilePath );

		// todo, check for common errors and throw informative errors in their place
		http url=versionFileUrl result="result";

		return DeSerializeJson( result.fileContent );
	}

	private string function _getRemoteBranchPath( required string branch ) output=false {
		var path = "presidecms/";

		switch( arguments.branch ) {
			case "bleedingEdge": return path & "bleeding-edge/";
			case "stable"      : return path & "stable/";
		}

		return path & "release/";
	}

// getters and setters
	private string function _getRepositoryUrl() output=false {
		return _repositoryUrl;
	}
	private void function _setRepositoryUrl( required string repositoryUrl ) output=false {
		_repositoryUrl = arguments.repositoryUrl;
	}

	private string function _getPresidePath() output=false {
		return _presidePath;
	}
	private void function _setPresidePath( required string presidePath ) output=false {
		_presidePath = arguments.presidePath;
	}

}