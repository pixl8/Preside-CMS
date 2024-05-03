/**
 * @presideservice
 * @singleton
 *
 */
component {

// CONSTRUCTOR

	/**
	 * @coldbox.inject                      coldbox
	 * @assetRendererService.inject         featureInjector:assetManager:AssetRendererService
	 * @widgetsService.inject               featureInjector:cms:WidgetsService
	 * @presideObjectService.inject         PresideObjectService
	 * @labelRendererService.inject         labelRendererService
	 * @renderedAssetCache.inject           cachebox:renderedAssetCache
	 * @dynamicFindAndReplaceService.inject dynamicFindAndReplaceService
	 */
	public any function init(
		  required any coldbox
		, required any assetRendererService
		, required any widgetsService
		, required any presideObjectService
		, required any labelRendererService
		, required any renderedAssetCache
		, required any dynamicFindAndReplaceService
	) {
		_setColdbox( arguments.coldbox );
		_setAssetRendererService( arguments.assetRendererService );
		_setWidgetsService( arguments.widgetsService );
		_setPresideObjectService( arguments.presideObjectService );
		_setLabelRendererService( arguments.labelRendererService );
		_setRenderedAssetCache( arguments.renderedAssetCache );
		_setDynamicFindAndReplaceService( arguments.dynamicFindAndReplaceService );

		_setCache( {} );
		_setRenderers( {} );

		return this;
	}

// PUBLIC API METHODS
	public any function render( required string renderer, required any data, any context="default", struct args={} ) {
		var interceptData = { content=arguments.data, renderer=arguments.renderer, context=arguments.context, args=args };
		var renderer      = _getRenderer( name=arguments.renderer, context=arguments.context );

		$announceInterception( "preRenderContent", interceptData );

		if ( renderer.isChain() ) {
			for( var r in renderer.getChain() ){
				interceptData.content = this.render( renderer=r, data=interceptData.content, context=arguments.context, args=arguments.args );
			}
		} else {
			var viewletArgs = IsStruct( arguments.data ) ? arguments.data : { data=arguments.data };
			viewletArgs.append( arguments.args, false );
			interceptData.content = _getColdbox().renderViewlet( event=renderer.getViewlet(), args=viewletArgs );
		}

		$announceInterception( "postRenderContent", interceptData );

		return interceptData.content;

	}

	public string function renderLabel(
		  required string objectName
		, required string recordId
		,          string keyField      = "id"
		,          string labelRenderer = $getPresideObjectService().getObjectAttribute( arguments.objectName, "labelRenderer" )
		,          array  bypassTenants = []
	) {
		var labelField           = _getPresideObjectService().getObjectAttribute(  arguments.objectName, "labelfield" );
		var labelRendererService = _getLabelRendererService();
		var selectFields         = arguments.labelRenderer.len() ? labelRendererService.getSelectFieldsForLabel( arguments.labelRenderer ) : ( Len( labelField ) ? [ "${labelfield} as label" ] : [] );

		if ( ArrayLen( selectFields ) ) {
			var poService       = _getPresideObjectService();
			var escapedKeyField = poService.getDbAdapterForObject( arguments.objectName ).escapeEntity( "#arguments.objectName#.#arguments.keyField#" );
			var record          = poService.selectData(
				  objectName         = arguments.objectName
				, filter             = "#escapedKeyField# = :keyField"
				, filterParams       = { "keyField"={ type="cf_sql_varchar", value=arguments.recordId } }
				, selectFields       = selectFields
				, allowDraftVersions = $getRequestContext().showNonLiveContent()
				, bypassTenants      = arguments.bypassTenants
			);

			if ( Len( Trim( arguments.labelRenderer ) ) ) {
				for( var r in record ) {
					return labelRendererService.renderLabel( arguments.labelRenderer, r );
				}
			}

			if ( record.recordCount ) {
				return record.label;
			}
		}

		return arguments.recordId;
	}

	public string function renderField(
		  required string  object
		, required string  property
		, required string  data
		,          any     context  = "default"
		,          boolean editable = false
		,          string  recordId = ""
		,          struct  record   = {}

	) {
		var renderer = _getRendererForPresideObjectProperty( arguments.object, arguments.property );
		var rendered = "";
		if ( rendererExists( renderer, arguments.context ) ) {
			rendered = this.render(
				  renderer = renderer
				, data     = arguments.data
				, context  = arguments.context
				, args     = {
					  objectName   = arguments.object
					, propertyName = arguments.property
					, recordId     = arguments.recordId
					, record       = arguments.record
				  }
			);
		} else {
			rendered = arguments.data;
		}

		if ( arguments.editable ) {
			rendered = makeContentEditable(
				  renderer        = renderer
				, object          = arguments.object
				, property        = arguments.property
				, recordId        = arguments.recordId
				, renderedContent = rendered
				, rawContent      = arguments.data
				, control         = _getControlForPresideObjectProperty( arguments.object, arguments.property )
			);
		}

		return rendered;
	}

	public string function renderEnum(
		  required string data
		,          string enum         = ""
		,          string objectName   = ""
		,          string propertyName = ""
		,          any    context      = "default"
		,          string recordId     = ""
		,          string enumRenderer = ""
	) {
		if ( !$helpers.isEmptyString( arguments.objectName ) && !$helpers.isEmptyString( arguments.propertyName ) ) {
			arguments.enumRenderer = $getPresideObjectService().getObjectPropertyAttribute( objectName=arguments.objectName, propertyName=arguments.propertyName, attributeName="enumRenderer", defaultValue="enumLabel" );
		} else if ( $helpers.isEmptyString( arguments.enumRenderer ) ) {
			arguments.enumRenderer = "enumLabel";
		}

		return this.render(
			  renderer = arguments.enumRenderer
			, data     = arguments.data
			, context  = arguments.context
			, args     = {
				  enum         = arguments.enum
				, objectName   = arguments.objectName
				, propertyName = arguments.propertyName
				, recordId     = arguments.recordId
			  }
		);
	}

	public string function makeContentEditable(
		  required string renderer
		, required string object
		, required string property
		, required string recordId
		, required string renderedContent
		, required string rawContent
		,          string control = "richeditor"
	) {

		return _getColdbox().renderViewlet( event="admin.frontendediting.renderFrontendEditor", args={
			  control         = arguments.control
			, renderer        = arguments.renderer
			, object          = arguments.object
			, property        = arguments.property
			, recordId        = arguments.recordId
			, renderedContent = arguments.renderedContent
			, rawContent      = arguments.rawContent
			, label           = _getPresideObjectService().getResourceBundleUriRoot( arguments.object ) & "field.#arguments.property#.title"
		} );
	}

	public array function listRenderers() {
		var renderers = StructKeyArray( _getRenderers() );
		ArraySort( renderers, "textnocase" );
		return renderers;
	}

	public boolean function rendererExists( required string name, any context="default" ) {
		var cache     = _getCache();
		var cacheKey  = "rendererExists: " & arguments.name & " in context: " & SerializeJson( arguments.context );

		if ( !StructKeyExists( cache, cacheKey ) ) {
			var exists   = false;
			var contexts = IsArray( arguments.context ) ? arguments.context : [ arguments.context ];

			if ( !contexts.find( "default" ) ) {
				contexts.append( "default" );
			}

			var renderers = _getRenderers();
			var cbProxy   = _getColdbox();

			if ( StructKeyExists( renderers, arguments.name ) ) {
				for( var cx in contexts ) {
					if ( StructKeyExists( renderers[ arguments.name ], cx ) ) {
						exists = true;
						break;
					}
				}
			}

			if ( !exists ) {
				for( var cx in contexts ) {
					exists = cbProxy.viewletExists( event=_getConventionBasedViewletName( renderer=arguments.name, context=cx ) );
					if ( exists ) {
						break;
					}
				}
			}

			cache[ cacheKey ] = exists;
		}

		return cache[ cacheKey ];
	}

	public void function registerRenderer( required string name, string context="default", string viewlet="", array chain=[] ) {
		var renderers = _getRenderers();

		if ( not StructKeyExists( renderers, arguments.name ) ) {
			renderers[ arguments.name ] = {};
		}

		renderers[ arguments.name ][ arguments.context ] = new ContentRenderer( viewlet=arguments.viewlet, chain=arguments.chain );

		return;
	}

	public void function registerMissingRenderer( required string name, string context="default" ) {
		var renderers = _getRenderers();

		if ( not StructKeyExists( renderers, arguments.name ) ) {
			renderers[ arguments.name ] = {};
		}

		renderers[ arguments.name ][ arguments.context ] = false;

		return;
	}

	public string function getRendererForField( required struct fieldAttributes ){
		// easy, the field has explicitly defined a renderer
		if ( Len( Trim( fieldAttributes.renderer ?: "" ) ) ) {
			return Trim( fieldAttributes.renderer );
		}

		// enum...
		if ( Len( Trim( fieldAttributes.enum ?: "" ) ) ) {
			return "enumLabel";
		}

		// just the plain old type?!
		if ( StructKeyExists( fieldAttributes, "type" ) ) {
			switch( fieldAttributes.type ){
				case "date":
					if ( StructKeyExists( fieldAttributes, "dbType" ) and ListFindNoCase( "timestamp,datetime", fieldAttributes.dbType ) ) {
						return "datetime";
					}
					if ( StructKeyExists( fieldAttributes, "dbType" ) and fieldAttributes.dbType == "date" ) {
						return "date";
					}
				break;
			}
		}

		// derive it from form control instead
		var control = fieldAttributes.control ?: "";
		if ( not Len( Trim( control ) ) or control eq "default" ) {
			control = _getPresideObjectService().getDefaultFormControlForPropertyAttributes( argumentCollection = fieldAttributes );
		}
		switch( control ) {
			case "richeditor":
				return "richeditor";
			break;
		}

		// cannot derive a renderer, just return field type or blank
		return fieldAttributes.type ?: "";
	}

	public string function renderEmbeddedImages( required string richContent, string context="richeditor", string postProcessor="", struct postProcessorArgs={} ) {
		if ( !$isFeatureEnabled( "cms" ) ) {
			return arguments.richContent;
		}

		var imgpattern = "\{\{image:(.*?):image\}\}";
		var outerargs  = arguments;

		return _getDynamicFindAndReplaceService().dynamicFindAndReplace( source=arguments.richContent, regexPattern=imgPattern, recurse=false, processor=function( captureGroups ){
			var img    = { placeholder=arguments.captureGroups[ 1 ] ?: "" };
			var config = UrlDecode( arguments.captureGroups[ 2 ] ?: "" );

			try {
				config = DeserializeJson( config );
				StructAppend( img, config );
			} catch( any e ){};

			if ( Len( Trim( img.asset ?: "" ) ) && Len( Trim( img.placeholder ?: "" ) ) ) {
				var cacheKey = "asset-#img.asset#-" & Serialize( img );
				var renderedImage = _getRenderedAssetCache().get( cacheKey );

				if ( IsNull( renderedImage ) ) {
					var args       = StructCopy( img );
					var derivative = args.derivative ?: "";

					StructDelete( args, "asset" );
					StructDelete( args, "placeholder" );
					StructDelete( args, "derivative" );

					if( Len( Trim( derivative ) ) && derivative NEQ "none" ){
						StructDelete( args, "width" );
						StructDelete( args, "height" );
						StructDelete( args, "quality" );
						StructDelete( args, "dimensions" );

						args.derivative = derivative;
					}

					renderedImage = _getAssetRendererService().renderAsset(
						  assetId = img.asset
						, context = outerargs.context
						, args    = args
					);

					_getRenderedAssetCache().set( cacheKey, renderedImage );
				}

				if ( Len( Trim( outerargs.postProcessor ) ) ) {
					outerargs.postProcessorArgs.html = renderedImage;
					renderedImage = $runEvent(
						  event          = outerargs.postProcessor
						, eventArguments = { args=outerargs.postProcessorArgs }
						, private        = true
						, prepostExempt  = true
					);
				}

				return renderedImage;
			}
			return "";
		} );
	}

	public string function renderEmbeddedAttachments( required string richContent, string context="richeditor", string postProcessor="", struct postProcessorArgs={} ) {
		var attachPattern = "\{\{attachment:(.*?):attachment\}\}";
		var outerargs  = arguments;

		return _getDynamicFindAndReplaceService().dynamicFindAndReplace( source=arguments.richContent, regexPattern=attachPattern, recurse=false, processor=function( captureGroups ){
			var embeddedAttachment = "";

			try {
				embeddedAttachment = DeserializeJson( UrlDecode( arguments.captureGroups[ 2 ] ?: "" ) );
			} catch ( any e ) {
				return "";
			}

			if ( Len( Trim( embeddedAttachment.asset ?: "" ) ) ) {
				var args = StructCopy( embeddedAttachment );

				StructDelete( args, "asset" );

				var renderedAttachment = _getAssetRendererService().renderAsset(
					  assetId = embeddedAttachment.asset
					, context = outerargs.context
					, args    = args
				);

				if ( Len( Trim( outerargs.postProcessor ) ) ) {
					outerargs.postProcessorArgs.html = renderedAttachment;
					renderedAttachment = $runEvent(
						  event          = outerargs.postProcessor
						, eventArguments = { args=outerargs.postProcessorArgs }
						, private        = true
						, prepostExempt  = true
					);
				}

				return renderedAttachment;
			}

			return "";
		} );
	}

	public void function renderCodeHighlighterIncludes( required string richContent, string context="richeditor" ) {
		var renderedContent = arguments.richContent;

		if ( _containsCodeSnippets( content=renderedContent ) ) {
			$getRequestContext().include( "highlightjs-css" )
				.include( "highlightjs" );
		}
	}

	public string function renderEmbeddedWidgets( required string richContent, string context="", string postProcessor="", struct postProcessorArgs={} ) {
		if ( !$isFeatureEnabled( "cms" ) ) {
			return arguments.richContent;
		}
		var widgetPattern = "\{\{widget:([a-zA-Z\$_][a-zA-Z0-9\$_]*):(.*?):widget\}\}";
		var outerargs     = arguments;

		return _getDynamicFindAndReplaceService().dynamicFindAndReplace( source=arguments.richContent, regexPattern=widgetPattern, recurse=true, processor=function( captureGroups ){
			var embeddedWidget = {
				  id          = arguments.captureGroups[ 2 ] ?: ""
				, configJson  = arguments.captureGroups[ 3 ] ?: ""
			};

			if ( Len( embeddedWidget.id ) ) {
				var renderedWidget = _getWidgetsService().renderWidget(
					  widgetId   = embeddedWidget.id
					, configJson = embeddedWidget.configJson
					, context    = outerargs.context
				);

				if ( Len( Trim( outerargs.postProcessor ) ) ) {
					outerargs.postProcessorArgs.html = renderedWidget;
					renderedWidget = $runEvent(
						  event          = outerargs.postProcessor
						, eventArguments = { args=outerargs.postProcessorArgs }
						, private        = true
						, prepostExempt  = true
					);
				}

				return renderedWidget;
			}

			return "";
		} );
	}

	public string function renderEmbeddedLinks( required string richContent, string postProcessor="", struct postProcessorArgs={} ) {
		var linkPattern = "\{\{(link|asset|custom):(.*?):(link|asset|custom)\}\}";
		var outerargs  = arguments;

		return _getDynamicFindAndReplaceService().dynamicFindAndReplace( source=arguments.richContent, regexPattern=linkPattern, recurse=false, processor=function( captureGroups ){
			var renderedLink = "";
			var linkContent = arguments.captureGroups[ 3 ] ?: "";
			var type = arguments.captureGroups[ 2 ] ?: "";
			    type = type == "link" ? "page" : type;

			switch( type ) {
				case "page":
					renderedLink = _getColdbox().getRequestContext().buildLink( page=linkContent );
				break;
				case "asset":
					renderedLink = _getColdbox().getRequestContext().buildLink( assetId=linkContent );
				break;
				case "custom":
					try {
						var linkDetails = DeserializeJson( toString( toBinary( linkContent ) ) );
						var linkType    = linkDetails.type ?: "";

						if ( Len( Trim( linkType ) ) ) {
							try {
								renderedLink = _getColdbox().renderViewlet( event="admin.linkpicker.#linkType#.getHref", args=linkDetails );
							} catch( any e ) {}
						} else {
							renderedLink = _getColdbox().getRequestContext().buildLink( argumentCollection=linkDetails );
						}
					} catch( any e ) {}
				break;
				default:
					renderedLink = linkContent;
			}

			if ( Len( Trim( renderedLink ) ) && Len( Trim( outerargs.postProcessor ) ) ) {
				outerargs.postProcessorArgs.html = renderedLink;
				renderedLink = $runEvent(
					  event          = outerargs.postProcessor
					, eventArguments = { args=outerargs.postProcessorArgs }
					, private        = true
					, prepostExempt  = true
				);
			}

			return renderedLink;
		} );
	}

// PRIVATE HELPERS
	private ContentRenderer function _getRenderer( required string name, required any context ) {
		var renderers            = _getRenderers();
		var cbProxy              = _getColdbox();
		var conventionsBasedName = "";
		var contexts             = IsArray( arguments.context ) ? arguments.context : [ arguments.context ];

		if ( StructKeyExists( renderers, arguments.name ) ) {
			for( var cx in contexts ) {
				if ( StructKeyExists( renderers[ arguments.name ], cx ) && IsValid( "component", renderers[ arguments.name ][ cx ] ) ) {
					return renderers[ arguments.name ][ cx ];
				} else {
					var renderer =_registerRendererByConvention( arguments.name, cx );
					if ( IsValid( "component", renderer ?: "" ) ) {
						return renderer;
					}
				}
			}
		}

		for( var cx in contexts ) {
			var renderer =_registerRendererByConvention( arguments.name, cx );
			if ( IsValid( "component", renderer ?: "" ) ) {
				return renderer;
			}
		}

		if ( !IsSimpleValue( arguments.context ) || arguments.context != "default" ) {
			return _getRenderer( arguments.name, "default" );
		}

		if ( StructKeyExists( renderers, arguments.name ) ) {
			for( var cx in renderers[ arguments.name ] ) {
				if ( IsValid( "component", renderers[ arguments.name ][ cx ] ) ) {
					throw(
						  type    = "Renderer.MissingDefaultContext"
						, message = "The renderer, [#arguments.name#], does not have a default context"
					);
				}
			}
		}

		throw(
			  type    = "Renderer.MissingRenderer"
			, message = "The renderer, [#arguments.name#], is not registered with the Preside rendering service"
		);
	}

	private any function _registerRendererByConvention( required string renderer, required string context ) {
		var conventionsBasedName = _getConventionBasedViewletName( arguments.renderer, arguments.context );

		if ( _getColdbox().viewletExists( conventionsBasedName ) ) {
			registerRenderer( arguments.renderer, arguments.context, conventionsBasedName );
			return new ContentRenderer( viewlet=conventionsBasedName, chain=[] );
		} else {
			registerMissingRenderer( arguments.renderer, arguments.context );
		}
	}

	private string function _getConventionBasedViewletName( required string renderer, required string context ) {
		return "renderers.content.#arguments.renderer#.#arguments.context#";
	}

	private string function _getRendererForPresideObjectProperty( required string objectName, required string property ) {
		var cache    = _getCache();
		var cacheKey = "rendererFor: #arguments.objectName#.#arguments.property#";

		if ( !StructKeyExists( cache, cacheKey ) ) {
			var poService = _getPresideObjectService();
			var fieldName = arguments.property;

			if ( !poService.fieldExists( arguments.objectName, arguments.property ) && ListFindNoCase( "label,${label}", arguments.property ) ) {
				fieldName = poService.getObjectAttribute( arguments.objectName, "labelfield", "label" );
			}

			var field = poService.getObjectProperty(
				  objectName   = arguments.objectName
				, propertyName = fieldName
			);

			cache[ cacheKey ] = getRendererForField( fieldAttributes=field );
		}

		return cache[ cacheKey ];
	}

	private string function _getControlForPresideObjectProperty( required string objectName, required string property ) {
		var cache    = _getCache();
		var cacheKey = "controlFor: #arguments.objectName#.#arguments.property#";

		if ( !StructKeyExists( cache, cacheKey ) ) {
			var poService = _getPresideObjectService();
			var field     = poService.getObjectProperty(
				  objectName   = arguments.objectName
				, propertyName = arguments.property
			);

			cache[ cacheKey ] = poService.getDefaultFormControlForPropertyAttributes( argumentCollection = field );
		}

		return cache[ cacheKey ];
	}

	private boolean function _containsCodeSnippets( required string content ) {
		return ReFind( '<code class="language-.*"', content );
	}


// GETTERS AND SETTERS
	private any function _getColdbox() {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) {
		_coldbox = arguments.coldbox;
	}
	private any function _getCache() {
		return _cache;
	}
	private void function _setCache( required any cache ) {
		_cache = arguments.cache;
	}

	private struct function _getRenderers() {
		return _renderers;
	}
	private void function _setRenderers( required struct renderers ) {
		_renderers = arguments.renderers;
	}

	private any function _getAssetRendererService() {
		return _assetRendererService;
	}
	private void function _setAssetRendererService( required any assetRendererService ) {
		_assetRendererService = arguments.assetRendererService;
	}

	private any function _getWidgetsService() {
		return _widgetsService;
	}
	private void function _setWidgetsService( required any widgetsService ) {
		_widgetsService = arguments.widgetsService;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getLabelRendererService() {
		return _labelRendererService;
	}
	private void function _setLabelRendererService( required any labelRendererService ) {
		_labelRendererService = arguments.labelRendererService;
	}

	private any function _getRenderedAssetCache() {
	    return _renderedAssetCache;
	}
	private void function _setRenderedAssetCache( required any renderedAssetCache ) {
	    _renderedAssetCache = arguments.renderedAssetCache;
	}

	private any function _getDynamicFindAndReplaceService() {
	    return _dynamicFindAndReplaceService;
	}
	private void function _setDynamicFindAndReplaceService( required any dynamicFindAndReplaceService ) {
	    _dynamicFindAndReplaceService = arguments.dynamicFindAndReplaceService;
	}
}