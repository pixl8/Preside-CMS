/**
 * The Update Manager Service provides the APIs
 * for managing the installed version of core Preside
 * for your application.
 *
 * @singleton
 *
 */
component {

// constructor
	public any function init( string presidePath="/preside" ) {
		_setPresidePath( arguments.presidePath );

		return this;
	}

// public methods
	public string function getCurrentVersion() {
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

	public string function getCurrentVersionFromBoxFile() {
		var boxFile = ListAppend( _getPresidePath(), "box.json", "/" );
		var boxFileContent = "";

		if ( !FileExists( boxFile ) ) {
			return "unknown";
		}

		try {
			boxFileContent = DeSerializeJson( FileRead( boxFile ) );
		} catch ( any e ) {
			return "unknown";
		}

		return boxFileContent.version ?: "unknown";
	}

	public string function detectCurrentVersion() {
		var version = getCurrentVersion();

		if ( version != "unknown" ) {
			return version;
		}

		version = getCurrentVersionFromBoxFile();

		if ( version != "unknown" ) {
			return version;
		}

		if ( isGitClone() ) {
			var gitbranch = getGitBranch();
			if ( listFirst( gitbranch, "-" ) == "release" ) {
				return listLast( gitbranch, "-" );
			}
		}

		return "unknown";
	}

	public boolean function isGitClone() {
		var gitDir = _getPresidePath() & "/.git/";

		return getCurrentVersion() == "unknown" && DirectoryExists( gitDir );
	}

	public string function getGitBranch() {
		var headFile = _getPresidePath() & "/.git/HEAD";

		if ( FileExists( headFile ) ) {
			try {
				var head = FileRead( headFile );

				return Trim( ReReplace( head, "^ref: refs\/heads\/", "" ) );
			} catch( any e ){
				"unknown";
			}
		}

		return "unknown";
	}

	public numeric function compareVersions( required string versionA, required string versionB ) {
		if ( versionA == versionB ) {
			return 0;
		}

		var a = ListToArray( versionA, "." );
		var b = ListToArray( versionB, "." );

		for( var i=1; i <= a.len(); i++ ) {
			if ( b.len() < i ) {
				return 1;
			}
			if ( a[i] > b[i] ) {
				return 1;
			}
			if ( a[i] < b[i] ) {
				return -1;
			}
		}

		return -1;
	}

// getters and setters
	private string function _getPresidePath() {
		return _presidePath;
	}
	private void function _setPresidePath( required string presidePath ) {
		_presidePath = arguments.presidePath;
	}

}