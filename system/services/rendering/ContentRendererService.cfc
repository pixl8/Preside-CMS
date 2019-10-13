/**
 * @presideservice
 * @singleton
 *
 */
component {

// CONSTRUCTOR

	/**
	 * @coldbox.inject              coldbox
	 * @assetRendererService.inject AssetRendererService
	 * @widgetsService.inject       WidgetsService
	 * @presideObjectService.inject PresideObjectService
	 * @labelRendererService.inject labelRendererService
	 * @renderedAssetCache.inject   cachebox:renderedAssetCache
	 */
	public any function init(
		  required any coldbox
		, required any assetRendererService
		, required any widgetsService
		, required any presideObjectService
		, required any labelRendererService
		, required any renderedAssetCache
	) {
		_setColdbox( arguments.coldbox );
		_setAssetRendererService( arguments.assetRendererService );
		_setWidgetsService( arguments.widgetsService );
		_setPresideObjectService( arguments.presideObjectService );
		_setLabelRendererService( arguments.labelRendererService );
		_setRenderedAssetCache( arguments.renderedAssetCache );

		_setCache( {} );
		_setRenderers( {} );

		return this;
	}

// PUBLIC API METHODS
	public any function render( required string renderer, required any data, any context="default", struct args={} ) {
		var renderer = _getRenderer( name=arguments.renderer, context=arguments.context );
		var r        = "";
		var rendered = arguments.data;

		if ( renderer.isChain() ) {
			for( r in renderer.getChain() ){
				rendered = this.render( renderer=r, data=rendered, context=arguments.context, args=arguments.args );
			}

			return rendered;
		} else {
			var viewletArgs = IsStruct( arguments.data ) ? arguments.data : { data=arguments.data };
			viewletArgs.append( arguments.args, false );
			return _getColdbox().renderViewlet( event=renderer.getViewlet(), args=viewletArgs );
		}
	}

	public string function renderLabel(
		  required string objectName
		, required string recordId
		,          string keyField      = "id"
		,          string labelRenderer = $getPresideObjectService().getObjectAttribute( arguments.objectName, "labelRenderer" )
		,          array bypassTenants = []
	) {

		var labelRendererService = _getLabelRendererService();
		var selectFields = arguments.labelRenderer.len() ? labelRendererService.getSelectFieldsForLabel( arguments.labelRenderer ) : [ "${labelfield} as label" ]
		var record = _getPresideObjectService().selectData(
			  objectName         = arguments.objectName
			, filter             = { "#keyField#"=arguments.recordId }
			, selectFields       = selectFields
			, allowDraftVersions = $getRequestContext().showNonLiveContent()
			, bypassTenants     = arguments.bypassTenants
		);

		if ( Len( Trim( arguments.labelRenderer ) ) ) {
			for( var r in record ) {
				return labelRendererService.renderLabel( arguments.labelRenderer, r );
			}
		}

		if ( record.recordCount ) {
			return record.label;
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

	public string function renderEmbeddedImages( required string richContent, string context="richeditor" ) {
		var embeddedImage   = "";
		var renderedImage   = "";
		var renderedContent = arguments.richContent;

		do {
			embeddedImage = _findNextEmbeddedImage( renderedContent );

			if ( Len( Trim( embeddedImage.asset ?: "" ) ) && Len( Trim( embeddedImage.placeholder ?: "" ) ) ) {
				var cacheKey = "asset-#embeddedImage.asset#-" & Serialize( embeddedImage );

				renderedImage = _getRenderedAssetCache().get( cacheKey );

				if ( IsNull( renderedImage ) ) {
					var args       = Duplicate( embeddedImage );
					var derivative = args.derivative ?: "";

					args.delete( "asset" );
					args.delete( "placeholder" );
					args.delete( "derivative" );

					if( Len( Trim( derivative ) ) && derivative NEQ "none" ){
						args.delete( "width" );
						args.delete( "height" );
						args.delete( "quality" );
						args.delete( "dimensions" );

						args.derivative = derivative;
					}

					renderedImage = _getAssetRendererService().renderAsset(
						  assetId = embeddedImage.asset
						, context = arguments.context
						, args    = args
					);

					_getRenderedAssetCache().set( cacheKey, renderedImage );
				}

				renderedContent = Replace( renderedContent, embeddedImage.placeholder, renderedImage, "all" );
			}

		} while ( StructCount( embeddedImage ) );

		return renderedContent;
	}

	public string function renderEmbeddedAttachments( required string richContent, string context="richeditor" ) {
		var embeddedAttachment   = "";
		var renderedAttachment   = "";
		var renderedContent = arguments.richContent;

		do {
			embeddedAttachment = _findNextEmbeddedAttachment( renderedContent );

			if ( Len( Trim( embeddedAttachment.asset ?: "" ) ) ) {
				var args = Duplicate( embeddedAttachment );

				args.delete( "asset" );
				args.delete( "placeholder" );

				renderedAttachment = _getAssetRendererService().renderAsset(
					  assetId = embeddedAttachment.asset
					, context = arguments.context
					, args    = args
				);
			}

			if ( Len( Trim( embeddedAttachment.placeholder ?: "" ) ) ) {
				renderedContent = Replace( renderedContent, embeddedAttachment.placeholder, renderedAttachment, "all" );
			}

		} while ( StructCount( embeddedAttachment ) );

		return renderedContent;
	}

	public void function renderCodeHighlighterIncludes( required string richContent, string context="richeditor" ) {
		var renderedContent = arguments.richContent;

		if ( _containsCodeSnippets( content=renderedContent ) ) {
			$getRequestContext().include( "highlightjs-css" )
				.include( "highlightjs" );
		}
	}

	public string function renderEmbeddedWidgets( required string richContent, string context="" ) {
		var embeddedWidget      = "";
		var renderedWidget      = "";
		var renderedContent = arguments.richContent;

		do {
			embeddedWidget = _findNextEmbeddedWidget( renderedContent );

			if ( StructCount( embeddedWidget ) ) {
				renderedWidget = _getWidgetsService().renderWidget(
					  widgetId = embeddedWidget.id
					, configJson     = embeddedWidget.configJson
					, context        = arguments.context
				);

				renderedContent = Replace( renderedContent, embeddedWidget.placeholder, renderedWidget, "all" );
			}

		} while ( StructCount( embeddedWidget ) );

		return renderedContent;
	}

	public string function renderEmbeddedLinks( required string richContent ) {
		var renderedContent = arguments.richContent;
		var embeddedLink    = "";
		var renderedLink    = "";

		do {
			embeddedLink = _findNextEmbeddedLink( renderedContent );

			if ( Len( Trim( embeddedLink.page ?: "" ) ) ) {
				renderedLink = _getColdbox().getRequestContext().buildLink( page=embeddedLink.page );
			}
			if ( Len( Trim( embeddedLink.asset ?: "" ) ) ) {
				renderedLink = _getColdbox().getRequestContext().buildLink( assetId=embeddedLink.asset );
			}
			if ( Len( Trim( embeddedLink.custom ?: "" ) ) ) {
				try {
					var linkDetails = DeserializeJson( toString( toBinary( embeddedLink.custom ) ) );
					var linkType    = linkDetails.type ?: "";

					if ( Len( Trim( linkType ) ) ) {
						try {
							renderedLink = _getColdbox().renderViewlet( event="admin.linkpicker.#linkType#.getHref", args=linkDetails );
						} catch( any e ) {}
					} else {
						renderedLink = _getColdbox().getRequestContext().buildLink( argumentCollection=linkDetails );
					}
				} catch( any e ) {}
			}

			if ( Len( Trim( embeddedLink.placeholder ?: "" ) ) ) {
				renderedContent = Replace( renderedContent, embeddedLink.placeholder, renderedLink, "all" );
			}

		} while ( StructCount( embeddedLink ) );

		return renderedContent;
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

	private struct function _findNextEmbeddedImage( required string richContent ) {
		// The following regex is designed to match the following pattern that would be embedded in rich editor content:
		// {{image:{asset:"assetId",option:"value",option2:"value"}:image}}


		var regex  = "{{image:(.*?):image}}";
		var match  = ReFindNoCase( regex, arguments.richContent, 1, true );
		var img    = {};
		var config = "";

		if ( ArrayLen( match.len ) eq 2 and match.len[1] and match.len[2] ) {
			img.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );

			config = Mid( arguments.richContent, match.pos[2], match.len[2] );
			config = UrlDecode( config );

			try {
				config = DeserializeJson( config );
				StructAppend( img, config );
			} catch ( any e ) {}
		}

		return img;
	}

	private struct function _findNextEmbeddedAttachment( required string richContent ) {
		// The following regex is designed to match the following pattern that would be embedded in rich editor content:
		// {{attachment:{asset:"assetId",option:"value",option2:"value"}:attachment}}


		var regex      = "{{attachment:(.*?):attachment}}";
		var match      = ReFindNoCase( regex, arguments.richContent, 1, true );
		var attachment = {};
		var config     = "";

		if ( ArrayLen( match.len ) eq 2 and match.len[1] and match.len[2] ) {
			attachment.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );

			config = Mid( arguments.richContent, match.pos[2], match.len[2] );
			config = UrlDecode( config );

			try {
				config = DeserializeJson( config );
				StructAppend( attachment, config );
			} catch ( any e ) {}
		}

		return attachment;
	}

	private struct function _findNextEmbeddedWidget( required string richContent ) {
		// The following regex is designed to match the following pattern that would be embedded in rich editor content:
		// {{widget:myWidgetId:{option:"value",option2:"value"}:widget}}


		var regex = "{{widget:([a-z\$_][a-z0-9\$_]*):(.*?):widget}}";
		var match = ReFindNoCase( regex, arguments.richContent, 1, true );
		var widget    = {};

		if ( ArrayLen( match.len ) eq 3 and match.len[1] and match.len[2] and match.len[3] ) {
			widget.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );
			widget.id          = Mid( arguments.richContent, match.pos[2], match.len[2] );
			widget.configJson  = Mid( arguments.richContent, match.pos[3], match.len[3] );
		}

		return widget;
	}

	private struct function _findNextEmbeddedLink( required string richContent ) {
		// The following regex is designed to match the following patterns that would be embedded in rich editor content:
		// {{link:pageid:link}}
		// {{asset:assetid:asset}}


		var regex = "{{(link|asset|custom):(.*?):(link|asset|custom)}}";
		var match = ReFindNoCase( regex, arguments.richContent, 1, true );
		var link  = {};
		var type  = "";

		if ( ArrayLen( match.len ) eq 4 and match.len[1] and match.len[3] ) {
			type             = Mid( arguments.richContent, match.pos[2], match.len[2] );
			type             = type == "link" ? "page" : type;
			link.placeHolder = Mid( arguments.richContent, match.pos[1], match.len[1] );
			link[ type ]     = Mid( arguments.richContent, match.pos[3], match.len[3] );
		}

		return link;
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
}