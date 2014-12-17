component output=false {

// CONSTRUCTOR
	public any function init( string logDirectory=ExpandPath( "/logs" ) ) output=false {
		_setLogDirectory( arguments.logDirectory );
		return this;
	}

// PUBLIC API METHODS
	public void function raiseError( required struct error ) output=false {
		var rendered = "";
		var catch    = arguments.error;
		var fileName = "rte-" & GetTickCount() & ".html";
		var filePath = _getLogDirectory() & "/" & filename;

		savecontent variable="rendered" {
			include template="errorTemplate.cfm";
		}
		FileWrite( filePath, Trim( rendered ) );

		_callErrorListeners( arguments.error );
	}

	public array function listErrors() output=false {
		var files = DirectoryList( _getLogDirectory(), false, "query", "rte-*.html" );
		var errors = [];

		for( var file in files ) {
			errors.append( { date=file.dateLastModified, filename=file.name } );
		}

		errors.sort( function( a, b ){
			return a.date < b.date ? 1 : -1;
		} );

		return errors;
	}

	public string function readError( required string logFile ) output=false {
		try {
			return FileRead( _getLogDirectory() & "/" & arguments.logFile );
		} catch( any e ) {
			return "";
		}
	}

	public void function deleteError( required string logFile ) output=false {
		try {
			return FileDelete( _getLogDirectory() & "/" & arguments.logFile );
		} catch( any e ) {
		}
	}

	public void function deleteAllErrors() output=false {
		listErrors().each( function( err ){
			deleteError( err.filename );
		} );
	}

// PRIVATE HELPERS
	private void function _callErrorListeners( required struct error ) output=false {
		_callListener( "app.services.errors.ErrorHandler", arguments.error );

		var extensions = new preside.system.services.devtools.ExtensionManagerService( "/app/extensions" ).listExtensions( activeOnly=true );
		for( var extension in extensions ) {
			_callListener( "app.extensions.#extension.name#.services.errors.ErrorHandler", arguments.error );
		}
	}

	private void function _callListener( required string listenerPath, required struct error ) output=false {
		var filePath = ExpandPath( "/" & Replace( arguments.listenerPath, ".", "/", "all" ) & ".cfc" );
		if ( FileExists( filePath ) ) {
			try {
				CreateObject( arguments.listenerPath ).raiseError( arguments.error );
			} catch ( any e ){}
		}
	}

// GETTERS AND SETTERS
	private any function _getLogDirectory() output=false {
		return _logDirectory;
	}
	private void function _setLogDirectory( required any logDirectory ) output=false {
		_logDirectory = Replace( arguments.logDirectory, "\", "/", "all" );
		_logDirectory = ReReplace( _logDirectory, "/$", "" );
	}

}