/**
 * I am a utitlity component to take a CFC and create an reStructuredText document that
 * documents its API
 */
component output=false {

	variables.NEWLINE    = Chr( 10 );
	variables.DOUBLELINE = NEWLINE & NEWLINE;
	variables.INDENT     = "    ";

	/**
	 * Returns a string containing the reStructuredText documentation
	 * for the given component path.
	 *
	 * @componentPath.hint Component path used to instantiate the component, e.g. "preside.system.presideobjects.PresideObjectService"
	 *
	 */
	public string function createCFCDocumentation( required string componentPath ) output=false {
		var meta = GetComponentMetaData( arguments.componentPath );
		var doc  = CreateObject( "java", "java.lang.StringBuffer" );
		var objName = ListLast( arguments.componentPath, "." );
		var title = meta.displayName ?: objName;


		doc.append( _rstTitle( title ) );

		doc.append( DOUBLELINE & _rstTitle( "Overview", "-" ) & DOUBLELINE );
		doc.append( "**Full path:** *#arguments.componentPath#*" );

		if ( Len( Trim( meta.hint ?: "" ) ) ) {
			doc.append( DOUBLELINE & _parseHint( meta.hint ) );
		}


		if ( ( meta.functions ?: [] ).len() ) {
			doc.append( DOUBLELINE & _rstTitle( "Public API Methods", "-" ) );

			for( var fun in meta.functions ){
				if ( ( fun.access ?: "" ) == "public" && IsBoolean( fun.autodoc ?: "" ) && fun.autodoc ) {
					doc.append( _createFunctionDoc( fun ) );
				}
			}
		}

		return doc.toString();
	}

	/**
	 * Returns a string containing the reStructuredText documentation
	 * for the given preside object
	 *
	 * @componentPath.hint Component path used to instantiate the component, e.g. "preside.system.preside-objects.page"
	 *
	 */
	public string function createPresideObjectDocumentation( required string componentPath ) output=false {
		var meta = GetComponentMetaData( arguments.componentPath );
		var doc  = CreateObject( "java", "java.lang.StringBuffer" );
		var objName = ListLast( arguments.componentPath, "." );
		var title = meta.displayName ?: objName;

		doc.append( _rstTitle( title ) );

		doc.append( DOUBLELINE & _rstTitle( "Overview", "-" ) & DOUBLELINE );

		if ( Len( Trim( meta.hint ?: "" ) ) ) {
			doc.append( _parseHint( meta.hint ) & DOUBLELINE );
		}

		doc.append( "**Object name:**" & NEWLINE & INDENT & ListLast( arguments.componentPath, "." ) & DOUBLELINE );
		doc.append( "**Table name:**" & NEWLINE & INDENT & "psys_" & ListLast( arguments.componentPath, "." ) & DOUBLELINE );
		doc.append( "**Path:**" & NEWLINE & INDENT & "/" & Replace( Replace( arguments.componentPath, "preside.system.", "" ), ".", "/", "all" ) & ".cfc" );


		doc.append( DOUBLELINE & _rstTitle( "Properties", "-" ) & DOUBLELINE );
		doc.append( ".. code-block:: java" & DOUBLELINE );
		doc.append( _parsePresideObjectPropertiesAsCode( arguments.componentPath ) );

		if ( ( meta.functions ?: [] ).len() ) {
			doc.append( DOUBLELINE & _rstTitle( "Public API Methods", "-" ) );

			for( var fun in meta.functions ){
				if ( ( fun.access ?: "" ) == "public" && IsBoolean( fun.autodoc ?: "" ) && fun.autodoc ) {
					doc.append( _createFunctionDoc( fun ) );
				}
			}
		}

		return doc.toString();
	}


	/**
	 * Takes a Preside XML Form path and writes an .rst file to the passed folder.
	 * Returns a structure with information about the operation and parsed file.
	 *
	 * @xmlFilePath.hint  Full path to the XML file
	 * @docDirectory.hint Full directory path for the location of the rst file
	 */
	public struct function writeXmlFormDocumentation( required string xmlFilePath, required string docDirectory ) output=true {
		var returnStruct       = { success=true };
		var fileContent        = FileRead( arguments.xmlFilePath );
		var documentationMatch = ReFind( "<!--##!autodoc(.*?)-->", fileContent, 1, true );

		if ( !documentationMatch.len.len() == 2 || !documentationMatch.len[2] ) {
			return { success = false };
		}

		var documentation = Trim( Mid( fileContent, documentationMatch.pos[2], documentationMatch.len[2] ) );
		var title         = ListFirst( documentation, Chr(10) & Chr(13) );
		var description   = ListRest( documentation, Chr(10) & Chr(13) );
		var relativePath  = Replace( Replace( xmlFilePath, "\", "/", "all" ), ExpandPath( "/preside/system" ), "" );
		var source        = ReReplace( fileContent, "<!--##!autodoc(.*?)-->", "" );

		source = ReReplace( source, "\n", "`$$$", "all" );
		source = ListToArray( source, "`" );
		for( var i=1; i <= source.len(); i++ ){
			var line = source[i];
			if ( line != "$$$" ) {
				source[i] = INDENT & line;
			}
		}
		source = ArrayToList( source, NEWLINE );
		source = Replace( source, "$$$", "", "all" );
		source = Replace( source, Chr(9), INDENT, "all" );

		returnStruct.filename = LCase( ReReplace( title, "\W", "", "all" ) );

		var doc = CreateObject( "java", "java.lang.StringBuffer" );

		doc.append( _rstTitle( title ) & DOUBLELINE );
		doc.append( "*#relativePath#*" & DOUBLELINE );
		doc.append( description & DOUBLELINE );
		doc.append( ".. code-block:: xml" & DOUBLELINE );
		doc.append( source & DOUBLELINE );

		FileWrite( arguments.docDirectory & "/#returnStruct.filename#.rst", doc.toString() );

		return returnStruct;

	}

// PRIVATE METHODS
	private string function _rstTitle( required string title, string underLineChar="=" ) output=false {
		return arguments.title & NEWLINE & RepeatString( arguments.underLineChar, Len( arguments.title ) );
	}

	private string function _parseHint( required string hint ) output=false {
		var parsed = Trim( hint );

		parsed = Replace( parsed, "\n", NEWLINE, "all" );
		parsed = Replace( parsed, "\t", INDENT, "all" );

		return parsed;
	}

	private string function _createFunctionDoc( required struct fun ) output=false {
		var functionDoc        = CreateObject( "java", "java.lang.StringBuffer" );
		var argumentsDoc       = _createArgumentsDoc( fun.parameters );
		var argsRenderedInHint = false;
		var functionTitle      = UCase( Left( fun.name, 1 ) ) & Right( fun.name, Len( fun.name )-1 );

		functionDoc.append( DOUBLELINE & ".. _#Trim( LCase( fun.name ) )#:")
		functionDoc.append( DOUBLELINE & _rstTitle( functionTitle & "()", "~" ) );
		functionDoc.append( DOUBLELINE & ".. code-block:: java" );

		functionDoc.append( DOUBLELINE & INDENT & _createFunctionSignature( fun ) );

		if ( Len( Trim( fun.hint ?: "" ) ) ) {
			var hint = _parseHint( fun.hint );
			if ( FindNoCase( "${arguments}", hint ) ) {
				hint = ReplaceNoCase( hint, "${arguments}", argumentsDoc );
				argsRenderedInHint = true;
			}
			functionDoc.append( DOUBLELINE & hint );
		}

		if ( !argsRenderedInHint ) {
			functionDoc.append( DOUBLELINE & argumentsDoc );
		}

		return functionDoc.toString();
	}

	private string function _createArgumentsDoc( required array args ) output=false {
		var argsDoc = _rstTitle( "Arguments", "." ) & DOUBLELINE;

		if ( !args.len() ) {
			argsDoc &= "*This method does not accept any arguments.*";
			return argsDoc;
		}

		var tableData = [];
		for( var arg in args ) {
			var def = _parseArgumentDefault( arg );
			tableData.append({
				  Name        = arg.name
				, Type        = arg.type
				, Description = arg.hint ?: ""
				, Required    = YesNoFormat( arg.required ) & ( ( def != "*none*" ) ? " (default=#def#)" : "" )
			});
		}
		argsDoc &= _createTable( tableData, [ "Name", "Type", "Required", "Description" ] );


		return argsDoc;
	}

	private string function _createFunctionSignature( required struct fun ) output=false {
		var signature = "public #fun.returnType# function #fun.name#(";
		var delim     = " ";

		for( var arg in fun.parameters ) {
			signature &= delim;
			if ( arg.required ) {
				signature &= "required ";
			}
			signature &= arg.type & " " & arg.name;

			var default = _parseArgumentDefault( arg );

			if ( default != "*none*" ) {
				signature &= '=' & default;
			}

			delim = ", ";
		}

		signature &= " )";

		return signature;
	}

	private string function _createTable( required array tableData, required array cols ) output=false {
		var colLengths = [];
		var table      = "";
		var colCount   = arguments.cols.len();

		for( var i=1; i <= colCount; i++ ){
			colLengths[ i ] = Len( arguments.cols[i] );
		}

		for( var n=1; n <= arguments.tableData.len(); n++ ) {
			for( var i=1; i <= colCount; i++ ){
				var colLen = Len( arguments.tableData[n][ arguments.cols[i] ] );
				if ( colLen > colLengths[i] ) {
					colLengths[i] = colLen;
				}
			}
		}

		var headerBars = "";
		for( var i=1; i <= colCount; i++ ){
			headerBars &= RepeatString( "=", colLengths[ i ] );
			if ( i < colCount ) {
				headerBars &= "  ";
			}
		}

		table = headerBars & NEWLINE;
		for( var i=1; i <= colCount; i++ ){
			table &= LJustify( arguments.cols[i], colLengths[ i ] );
			if ( i < colCount ) {
				table &= "  ";
			}
		}
		table &= NEWLINE & headerBars & NEWLINE;

		for( var n=1; n <= arguments.tableData.len(); n++ ) {
			for( var i=1; i <= colCount; i++ ){
				var colValue = arguments.tableData[n][ arguments.cols[i] ];
				table &= LJustify( colValue, colLengths[ i ] );
				if ( i < colCount ) {
					table &= "  ";
				}
			}
			table &= NEWLINE;
		}

		table &= headerBars & NEWLINE;

		return table;
	}

	private string function _parseArgumentDefault( required struct arg ) output=false {
		if ( arg.keyExists( "default" ) && arg.default != "[runtime expression]" ) {
			if ( IsBoolean( arg.default ) || IsNumeric( arg.default ) ) {
				return arg.default;
			}

			return '"#arg.default#"';
		} else if ( arg.keyExists( "docdefault" ) ) {
			return arg.docdefault;
		}

		return "*none*";
	}

	private string function _parsePresideObjectPropertiesAsCode( required string componentPath ) output=false {
		var filePath            = "/" & Replace( arguments.componentPath, ".", "/", "all" ) & ".cfc";
		var fileContent         = FileRead( filePath );
		var lines               = ListToArray( ReReplace( fileContent, "\n", "`$$$", "all" ), "`" );
		var props               = [];
		var prevLineWasProperty = false;

		for( var line in lines ){
			line = Trim( Replace( line, "$$$", "" ) );
			if ( prevLineWasProperty && line == "" ) {
				props.append( "$$$" );
			}

			prevLineWasProperty = ReFindNoCase( "^property\s.*$", line );
			if ( prevLineWasProperty ) {
				props.append( INDENT & line );
			}
		}

		props = ArrayToList( props, NEWLINE );
		props = Replace( props, "$$$", "", "all" );

		return props;
	}
}