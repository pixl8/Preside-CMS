/**
 * This service provides an abstraction for Preside to load
 * and produce an ignore file list for faster and leaner startups.
 *
 * @singleton
 */
component accessors=true {

	property name="read"    type="boolean" inject="coldbox:setting:ignoreFile.read";
	property name="write"   type="boolean" inject="coldbox:setting:ignoreFile.write";
	property name="path"    type="string"  inject="coldbox:setting:ignoreFile.path";
	property name="ignored" type="struct";

	function read() {
		if ( getRead() ) {
			if ( FileExists( getPath() ) ) {
				var content = FileRead( getPath() );
				if ( IsJson( content ) ) {
					var ignored = DeserializeJson( content );
					if ( IsStruct( ignored ) ) {
						setIgnored( ignored );
						return;
					}
				}
			}
		}
		setIgnored( {} );
	}

	function write() {
		if ( getWrite() ) {
			FileWrite( getPath(), SerializeJson( request._ignoreFile ?: {} ) );
		}
		setIgnored({}); // once we're done the write(), we don't care for this data any more
	}

	function isIgnored( fileType, filePath ) {
		if ( !getRead() ) {
			return false;
		}
		var ignored = getIgnored();

		return StructKeyExists( ignored, arguments.fileType ) && StructKeyExists( ignored[ arguments.fileType ], arguments.filePath );

	}

	function ignore( fileType, filePath ){
		if ( getWrite() ) {
			request._ignoreFile = request._ignoreFile ?: {};
			request._ignoreFile[ arguments.fileType ] = request._ignoreFile[ arguments.fileType ] ?: {};
			request._ignoreFile[ arguments.fileType ][ arguments.filePath ] = true;
		}
	};

	function getIgnored( ){
		return this.ignored ?: {};
	}


}