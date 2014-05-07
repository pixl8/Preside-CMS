component output=false {

// constructor
	public any function init(
		  required any   presideObjectService
		, required any   presideContentRenderer
		, required any   coldboxRenderer
		,          array viewDirectories=[]

	) output=false {
		_setPresideObjectService  ( arguments.presideObjectService );
		_setPresideContentRenderer( arguments.presideContentRenderer );
		_setColdboxRenderer       ( arguments.coldboxRenderer );

		_loadViews( arguments.viewDirectories );
	}

// public api methods
	public boolean function viewExists( required string object, string view="index" ) output=false {
		var objectViews = _getObjectViews();

		return StructKeyExists( objectViews, arguments.object ) and StructKeyExists( objectViews[ arguments.object ], arguments.view );
	}

	public any function renderView( required string object, string view="index", boolean pageView=false , string returntype="string") output=false {
		var view           = _getView( arguments.object, arguments.pageView ? "__pagetype" & arguments.view : arguments.view );
		var selectDataArgs = Duplicate( arguments );
		var data           = "";
		var record         = "";
		var rendered       = CreateObject( "java", "java.lang.StringBuffer" );
		StructDelete( selectDataArgs, "object" );
		StructDelete( selectDataArgs, "view"   );
		StructDelete( selectDataArgs, "layout" );
		selectDataArgs.objectName   = arguments.object
		selectDataArgs.selectFields = view.selectFields

		data = _getPresideObjectService().selectData( argumentCollection = selectDataArgs );
		for( record in data ) {
			rendered.append( _getColdboxRenderer().renderView(
				  view     = view.viewPath
				, args     = _renderFields( arguments.object, record, view.fieldOptions )
				, _counter = data.currentRow
				, _records = data.recordCount
			) );
		}

		if ( arguments.returntype == "struct" ) {
			return {
				  recordcount = data.getrecordcount()
				, rendered    = rendered.toString()
				, data        = data
				, columnlist  = data.getColumnlist(false)
			}
		}else{
			return rendered.toString();
		}

	}

// private helpers
	private struct function _getView( required string object, required string view ) output=false {
		var objectViews = _getObjectViews();

		if ( StructKeyExists( objectViews, arguments.object ) and StructKeyExists( objectViews[ arguments.object ], arguments.view ) ) {
			return objectViews[ arguments.object ][ arguments.view ];
		}

		throw( type="presideObjectViewService.missingView", message="Object view not found for object named, [#arguments.object#], and view named, [#arguments.view#]" );
	}

	private void function _loadViews( required array viewDirectories ) output=false {
		var objectViews = {};
		var dir         = "";
		var subdirs     = "";
		var subdir      = "";
		var files       = "";
		var file        = "";
		var viewName    = "";
		var objectName  = "";

		for( dir in arguments.viewDirectories ) {
			dir     = ReReplace( dir, "[\\/]$", "" ) & "/preside-objects";
			subDirs = DirectoryList( dir, false, "query" );

			for( subDir in subDirs ){
				if ( subDir.type eq "Dir" ) {
					objectName = subDir.name;
					if ( not StructKeyExists( objectViews, objectName ) ) {
						objectViews[ objectName ] = {};
					}

					files = DirectoryList( dir & "/" & objectName, false, "path", "*.cfm" );
					for( file in files ){
						viewName = ReReplace( ListLast( file, "\/" ), "\.cfm$", "" );
						objectViews[ objectName ][ viewName ] = {
							  filePath = file
							, viewPath = "/preside-objects/#objectName#/#viewName#"
						};
					}
				}
			}

			dir     = ReReplace( dir, "preside\-objects$", "page-types" );
			subdirs = DirectoryList( dir, false, "query" );
			for( subdir in subdirs ) {
				if ( subdir.type == "Dir" ) {
					objectName = subdir.name;
					files = DirectoryList( dir & "/" & subdir.name, false, "path", "*.cfm" );
					for( file in files ) {
						viewName = ReReplace( ListLast( file, "\/" ), "\.cfm$", "" );
						objectViews[ objectName ][ "__pagetype" & viewName ] = {
							  filePath = file
							, viewPath = "/page-types/#objectName#/#viewName#"
						};
					}
				}
			}
		}

		for( var objectName in objectViews ) {
			for( var viewName in objectViews[ objectName ] ) {
				StructAppend( objectViews[ objectName ][ viewName ], _parseFieldsFromViewFile(
					  filePath   = objectViews[ objectName ][ viewName ].filePath
					, objectName = objectName
				) );
			}
		}

		_setObjectViews( objectViews );
	}

	private struct function _parseFieldsFromViewFile( required string filePath, required string objectName ) output=false {
		var fields          = { selectFields=[], fieldOptions={} };
		var fileContent     = FileExists( arguments.filePath ) ? FileRead( arguments.filePath ) : "";
		var regexes         = [ '<' & 'cfparam\s[^>]*?name\s*=\s*"args\.(.*?)".*?>', 'param\s[^;]*?name\s*=\s*"args\.(.*?)".*?;' ];
		var fieldRegex      = 'field\s*=\s*"(.*?)"';
		var rendererRegex   = 'renderer\s*=\s*"(.*?)"';
		var editableRegex   = 'editable\s*=\s*(true|"true")'
		var result          = "";
		var startPos        = 1;
		var match           = "";
		var alias           = "";
		var fieldName       = "";
		var selectDef       = "";
		var i               = 0;
		var idFieldIncluded = false;

		fileContent = _stripCfComments( fileContent );

		for( i=1; i lte regexes.len(); i++ ) {
			startPos = 1;
			while( startPos ){
				result = ReFindNoCase( regexes[i], fileContent, startPos, true );
				startPos = result.pos.len() eq 2 ? result.pos[2] : 0;
				if ( startPos ) {
					match = Mid( fileContent, result.pos[1], result.len[1] );
					alias = Mid( fileContent, result.pos[2], result.len[2] );
					result = ReFindNoCase( fieldRegex, match, 1, true );
					fieldName = result.pos.len() eq 2 and result.pos[2] ? Mid( match, result.pos[2], result.len[2] ) : ( objectName & "." & alias );

					selectDef = alias eq fieldName ? alias : "#fieldName# as #alias#";
					if ( not fields.selectFields.find( selectDef ) ) {
						fields.selectFields.append( selectDef );

						result = ReFindNoCase( rendererRegex, match, 1, true );
						fields.fieldOptions[ alias ] = {
							  editable = ReFindNoCase( editableRegex, match ) != 0
							, renderer = result.pos.len() eq 2 and result.pos[2] ? Mid( match, result.pos[2], result.len[2] ) : ""
							, field    = fieldName
						};
					}
				}
			}
		}

		fields.selectFields.append( "#objectName#.id as _id" );

		return fields;
	}

	private struct function _renderFields( required string objectName, required struct record, required struct fieldOptions ) output=false {
		var rendererSvc = _getPresideContentRenderer();
		var poService   = _getPresideObjectService();

		for( var field in record ){
			var rendered = record[ field ];

			if ( StructKeyExists( fieldOptions, field ) && fieldOptions[ field ].renderer != "none" ) {
				var property = "";

				if ( !Len( Trim( fieldOptions[ field ].renderer ) ) || fieldOptions[ field ].editable ) {
					property = _getPresideObjectPropertyBasedOnFieldSql( arguments.objectName, fieldOptions[ field ].field );
				}

				if ( Len( Trim( fieldOptions[ field ].renderer ) ) ) {
					rendered = rendererSvc.render( fieldOptions[ field ].renderer, rendered );
					if ( fieldOptions[ field ].editable && ( property._object ?: "" ) == arguments.objectName ) {
						rendered = rendererSvc.makeContentEditable(
							  renderer        = fieldOptions[ field ].renderer
							, object          = arguments.objectName
							, property        = property.name
							, recordId        = record._id
							, renderedContent = rendered
							, rawContent      = record[field]
						);
					}
				} elseif ( !StructIsEmpty( property ) ) {
					rendered = rendererSvc.renderField(
						  object   = property._object
						, property = property.name
						, data     = rendered
						, recordId = record._id
						, editable = fieldOptions[ field ].editable && ListFindNoCase( arguments.objectName & ",page", ( property._object ?: "" ) )
					);
				}

			}

			record[ field ] = rendered;
		}

		return record;
	}

	private struct function _getPresideObjectPropertyBasedOnFieldSql( required string objectName, required string fieldSql ) output=false {
		var objName   = ListLen( arguments.fieldSql, "." ) > 1 ? ListFirst( arguments.fieldSql, "." ) : arguments.objectName;
		var propName  = ListLen( arguments.fieldSql, "." ) > 1 ? ListRest( arguments.fieldSql, "." ) : arguments.fieldSql;
		var poService = _getPresideObjectService();

		if ( !poService.objectExists( objName ) || !poService.fieldExists( objName, propName ) ) {
			return {};
		}

		var prop = poService.getObjectProperty( objName, propName ).getMemento();
		prop._object = objName;

		return prop;
	}

	private string function _stripCfComments( content ) output=false {
		return ReReplace( content, "<!---(.*?)--->", "\1", "all" );
	}


// getters and setters
	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getPresideContentRenderer() output=false {
		return _presideContentRenderer;
	}
	private void function _setPresideContentRenderer( required any presideContentRenderer ) output=false {
		_presideContentRenderer = arguments.presideContentRenderer;
	}

	private any function _getColdboxRenderer() output=false {
		return _coldboxRenderer;
	}
	private void function _setColdboxRenderer( required any coldboxRenderer ) output=false {
		_coldboxRenderer = arguments.coldboxRenderer;
	}

	private struct function _getObjectViews() output=false {
		return _objectViews;
	}
	private void function _setObjectViews( required struct objectViews ) output=false {
		_objectViews = arguments.objectViews;
	}
}