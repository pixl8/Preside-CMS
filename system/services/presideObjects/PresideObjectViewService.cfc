/**
 * Service that provides logic for rendering
 * [[presidedataobjectviews]].
 *
 * @autodoc
 * @singleton
 * @presideService
 *
 */
component displayName="Preside Object View Service" {

// constructor
	/**
	 * @presideObjectService.inject   PresideObjectService
	 * @presideContentRenderer.inject ContentRendererService
	 * @coldboxRenderer.inject        presideRenderer
	 * @cachebox.inject               cachebox
	 */
	public any function init(
		  required any presideObjectService
		, required any presideContentRenderer
		, required any coldboxRenderer
		, required any cachebox

	) {
		_setPresideObjectService  ( arguments.presideObjectService   );
		_setPresideContentRenderer( arguments.presideContentRenderer );
		_setColdboxRenderer       ( arguments.coldboxRenderer        );
		_setCacheBox              ( arguments.cachebox               );
		_setSimpleLocalCache      ( {}                               );
	}

// public api methods
	/**
	 * Renders a view using data from the Preside Object layer.
	 * See [[presidedataobjectviews]] for a full guide.
	 * \n
	 * >>> The method will accept any _extra_ arguments not defined
	 * here and use them in its call to [[presideobjectservice-selectdata]].
	 * Any arguments valid for the [[presideobjectservice-selectdata]]
	 * method are valid here.
	 *
	 * @autodoc
	 * @presideObject.hint          The name of the object from which to select data for the view
	 * @view.hint                   The view path (a regular coldbox view path)
	 * @returntype.hint             Either "struct" or "string". If "struct", the method will return additional information about the recordset used to render the view. If "String", just the rendered view will be returned.
	 * @args.hint                   A data struct that will be passed to the view
	 * @cache.hint                  Whether or not to cache the result
	 * @cacheAutoKey.hint           When caching, whether or not to automatically generate a suitable cache key that attempts to be invalidated when the source data changes.
	 * @cacheTimeout.hint           Optional numeric cache timeout. See [Cachebox documentation](https://www.gitbook.com/book/ortus/cachebox-documentation/details) for more details on cache timeouts, etc.
	 * @cacheLastAccessTimeout.hint Optional numeric cache last access timeout. See [Cachebox documentation](https://www.gitbook.com/book/ortus/cachebox-documentation/details) for more details on cache timeouts, etc.
	 * @cacheSuffix.hint            Optional manual cache key suffix. This is an alternative to using the 'cacheAutoKey' argument. If using this argument, ensure unique cache suffixes for distinct calls to this method.
	 * @cacheProvider.hint          Optional specific alternative cache provider in which to store the cached view. Defaults to the standard ColdBox "template" cache. Optional numeric cache timeout. See [Cachebox documentation](https://www.gitbook.com/book/ortus/cachebox-documentation/details) for more details on cache providers, etc.
	 */
	public any function renderView(
		  required string  presideObject
		, required string  view
		,          boolean autoGroupBy            = true
		,          string  returntype             = "string"
		,          struct  args                   = {}
		,          boolean cache                  = false
		,          boolean cacheAutoKey           = true
		,          any     cacheTimeout           = ""
		,          any     cacheLastAccessTimeout = ""
		,          string  cacheSuffix            = ""
		,          string  cacheProvider          = "template"
	) {
		if ( arguments.cache ) {
			var cacheKey = _generateCacheKey( argumentCollection=arguments );
			var cached   = _getFromCache( cacheProvider=arguments.cacheProvider, cacheKey=cacheKey );

			if ( !IsNull( local.cached ) ) {
				return cached;
			}
		}

		var viewFilePath   = _getColdboxRenderer().locateView( arguments.view ) & ".cfm";
		var viewDetails    = _readView( arguments.presideObject, viewFilePath );
		var selectDataArgs = Duplicate( arguments );
		var data           = "";
		var record         = "";
		var rendered       = CreateObject( "java", "java.lang.StringBuffer" );
		var result         = "";

		StructDelete( selectDataArgs, "presideObject"          );
		StructDelete( selectDataArgs, "view"                   );
		StructDelete( selectDataArgs, "layout"                 );
		StructDelete( selectDataArgs, "cache"                  );
		StructDelete( selectDataArgs, "cacheAutoKey"           );
		StructDelete( selectDataArgs, "cacheLastAccessTimeout" );
		StructDelete( selectDataArgs, "cacheProvider"          );
		StructDelete( selectDataArgs, "cacheSuffix"            );
		StructDelete( selectDataArgs, "cacheTimeout"           );

		selectDataArgs.objectName         = arguments.presideObject;
		selectDataArgs.selectFields       = viewDetails.selectFields;
		selectDataArgs.allowDraftVersions = selectDataArgs.allowDraftVersions ?: $getRequestContext().showNonLiveContent();

		if ( selectDataArgs.allowDraftVersions ) {
			selectDataArgs.append( _getVersioningArgsForSelectData( argumentCollection=selectDataArgs ), false );
		}

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
			result = {
				  recordcount = data.getrecordcount()
				, rendered    = rendered.toString()
				, data        = data
				, columnlist  = data.getColumnlist(false)
			};
		} else {
			result = rendered.toString();
		}

		if ( arguments.cache ) {
			_saveToCache( argumentCollection=arguments, value=result, cacheKey=cacheKey );
		}

		return result;
	}

// private helpers
	private struct function _readView( required string object, required string viewPath ) {
		var cache    = _getSimpleLocalCache();
		var cacheKey = "_readView-#arguments.object#-#arguments.viewPath#";

		if ( !StructKeyExists( cache, cacheKey ) ) {
			cache[ cacheKey ] = _parseFieldsFromViewFile(
				  objectName = arguments.object
				, filePath   = arguments.viewPath
			);
		}

		return cache[ cacheKey ];
	}

	private struct function _parseFieldsFromViewFile( required string objectName, required string filePath ) {
		var fields          = { selectFields=[], fieldOptions={} };
		var paramFile       = arguments.filePath.reReplace( "\.cfm$", "$params.txt" );
		var fileContent     = FileExists( paramFile ) ? FileRead( paramFile ) : ( FileExists( arguments.filePath ) ? FileRead( arguments.filePath ) : "" );
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

	private struct function _renderFields( required string objectName, required struct record, required struct fieldOptions ) {
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
				} else if ( !StructIsEmpty( property ) ) {
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

	private struct function _getPresideObjectPropertyBasedOnFieldSql( required string objectName, required string fieldSql ) {
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

	private string function _stripCfComments( content ) {
		return ReReplace( content, "<!---(.*?)--->", "\1", "all" );
	}

	private any function _getFromCache( required string cacheKey, required string cacheProvider ) {
		return _getCacheBox().getCache( arguments.cacheProvider ).get( arguments.cacheKey );
	}

	private void function _saveToCache(
		  required string  cacheKey
		, required any     value
		, required string  cacheProvider          = "template"
		,          any     cacheTimeout           = ""
		,          any     cacheLastAccessTimeout = ""
	) {
		var cache    = _getCacheBox().getCache( arguments.cacheProvider );

		cache.set(
			  objectKey         = arguments.cacheKey
			, object            = arguments.value
			, timeout           = arguments.cacheTimeout
			, lastAccessTimeout = arguments.cacheLastAccessTimeout
		);
	}

	private string function _generateCacheKey(
		  required string  presideObject
		, required string  view
		, required boolean cacheAutoKey
		,          any     cacheTimeout = ""
		,          any     cacheLastAccessTimeout = ""
		,          string  cacheSuffix
		,          string  cacheProvider = "template"

	) {
		var cacheKey = "cachedPresideObjectView-#arguments.presideObject#-#arguments.view#-#arguments.cacheSuffix#";

		if ( !arguments.cacheAutoKey ) {
			return cacheKey;
		}

		var keyArgs        = Duplicate( arguments );
		var selectDataArgs = Duplicate( arguments );

		keyArgs.delete( "cacheAutoKey"           );
		keyArgs.delete( "cacheTimeout"           );
		keyArgs.delete( "cacheLastAccessTimeout" );
		keyArgs.delete( "cacheSuffix"            );
		keyArgs.delete( "cacheProvider"          );
		keyArgs.delete( "value"                  );


		selectDataArgs.objectName   = arguments.presideObject
		selectDataArgs.selectFields = [ "Max( #arguments.presideobject#.datemodified ) as datemodified" ];

		var lastRecordModified = _getPresideObjectService().selectData( argumentCollection=selectDataArgs );

		cacheKey &= Hash( SerializeJson( keyArgs ) & ( lastRecordModified.datemodified ?: "" ) );

		return cacheKey;

	}

	private struct function _getVersioningArgsForSelectData( required string objectName, string id="", any filter={}, struct filterParams={} ) {
		var coldbox = $getColdbox();
		var event   = coldbox.getRequestService().getContext();

		if ( event.isAdminUser() ) {
			var currentEvent = event.getCurrentEvent();

			if ( currentEvent == "core.SiteTreePageRequestHandler.index" && arguments.objectName == "page" || _getPresideObjectService().isPageType( arguments.objectName ) ) {
				var currentPageId = event.getCurrentPageId();

				if ( _isSelectDataForCurrentPage( currentPageId, arguments.id, arguments.filter, arguments.filterparams ) ) {
					return {
						  fromVersionTable = true
						, specificVersion  = Val( event.getValue( "version", 0 ) )
					};
				}
			}
		}

		return {};
	}

	private boolean function _isSelectDataForCurrentPage(
		  required string currentPageId
		, required string id
		, required any    filter
		, required struct filterparams
	) {
		if ( !Len( Trim( currentPageId ) ) ) {
			return false;
		}

		if ( arguments.id == currentPageId ) {
			return true;
		}

		if ( IsSimpleValue( arguments.filter.page       ?: [] ) && arguments.filter.page       == currentPageId ) {
			return true;
		}
		if ( IsSimpleValue( arguments.filterParams.page ?: [] ) && arguments.filterParams.page == currentPageId ) {
			return true;
		}
		if ( IsSimpleValue( arguments.filter.id         ?: [] ) && arguments.filter.id         == currentPageId ) {
			return true;
		}
		if ( IsSimpleValue( arguments.filterParams.id   ?: [] ) && arguments.filterParams.id   == currentPageId ) {
			return true;
		}

		return false;
	}


// getters and setters
	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getPresideContentRenderer() {
		return _presideContentRenderer;
	}
	private void function _setPresideContentRenderer( required any presideContentRenderer ) {
		_presideContentRenderer = arguments.presideContentRenderer;
	}

	private any function _getColdboxRenderer() {
		return _coldboxRenderer;
	}
	private void function _setColdboxRenderer( required any coldboxRenderer ) {
		_coldboxRenderer = arguments.coldboxRenderer;
	}
	private struct function _getSimpleLocalCache() {
	    return _simpleLocalCache;
	}
	private void function _setSimpleLocalCache( required struct simpleLocalCache ) {
	    _simpleLocalCache = arguments.simpleLocalCache;
	}

	private any function _getCacheBox() {
		return _cacheBox;
	}
	private void function _setCacheBox( required any cacheBox ) {
		_cacheBox = arguments.cacheBox;
	}
}