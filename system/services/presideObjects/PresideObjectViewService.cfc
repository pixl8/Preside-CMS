component output=false singleton=true {

// constructor
	/**
	 * @presideObjectService.inject   PresideObjectService
	 * @presideContentRenderer.inject ContentRendererService
	 * @coldboxRenderer.inject        coldbox:plugin:Renderer
	 * @cacheProvider.inject          cachebox:PresideObjectViewCache
	 */
	public any function init(
		  required any presideObjectService
		, required any presideContentRenderer
		, required any coldboxRenderer
		, required any cacheProvider

	) output=false {
		_setPresideObjectService  ( arguments.presideObjectService );
		_setPresideContentRenderer( arguments.presideContentRenderer );
		_setColdboxRenderer       ( arguments.coldboxRenderer );
		_setCacheProvider         ( arguments.cacheProvider );
	}

// public api methods
	public any function renderView( required string presideObject, required string view, string returntype="string", struct args={} ) output=false {
		var viewFilePath   = _getColdboxRenderer().locateView( arguments.view ) & ".cfm";
		var viewDetails    = _readView( arguments.presideObject, viewFilePath );
		var selectDataArgs = Duplicate( arguments );
		var data           = "";
		var record         = "";
		var rendered       = CreateObject( "java", "java.lang.StringBuffer" );

		StructDelete( selectDataArgs, "presideObject" );
		StructDelete( selectDataArgs, "view"   );
		StructDelete( selectDataArgs, "layout" );

		selectDataArgs.objectName   = arguments.presideObject
		selectDataArgs.selectFields = viewDetails.selectFields

		data = _getPresideObjectService().selectData( argumentCollection = selectDataArgs );
		for( record in data ) {
			var viewArgs = _renderFields( arguments.presideObject, record, viewDetails.fieldOptions );
			viewArgs.append( arguments.args );

			rendered.append( _getColdboxRenderer().renderView(
				  view     = arguments.view
				, args     = viewArgs
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
	private struct function _readView( required string object, required string viewPath ) output=false {
		var cacheKey = "PresideObjectService._readView() cache for object [#arguments.object#] and view path [#arguments.viewPath#]";
		var args     = Duplicate( arguments );

		return _getCacheProvider().getOrSet( cacheKey, function(){
			return _parseFieldsFromViewFile(
				  objectName = args.object
				, filePath   = args.viewPath
			)
		} );
	}

	private struct function _parseFieldsFromViewFile( required string objectName, required string filePath ) output=false {
		var fields          = { selectFields=[], fieldOptions={} };
		var fileContent     = FileExists( arguments.filePath ) ? FileRead( arguments.filePath ) : "";
		var regexes         = [ '<' & '(?:cfparam|cf_presideparam)\s[^>]*?name\s*=\s*"args\.(.*?)".*?>', 'param\s[^;]*?name\s*=\s*"args\.(.*?)".*?;' ];
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

					if ( fieldName != "false" ) {
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

		var prop = poService.getObjectProperty( objName, propName );
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
	private any function _getCacheProvider() output=false {
		return _CacheProvider;
	}
	private void function _setCacheProvider( required any CacheProvider ) output=false {
		_CacheProvider = arguments.CacheProvider;
	}
}