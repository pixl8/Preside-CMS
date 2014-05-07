component extends="preside.system.base.Service" output="false" {

// CONSTRUCTOR
	public any function init( required any coldbox, required any cache ) output=false {
		_setColdbox( arguments.coldbox );
		_setCache( arguments.cache );

		_setRenderers( {} );

		super.init( argumentCollection = arguments );

		return this;
	}

// PUBLIC API METHODS
	public string function render( required string renderer, required string data, string context="default" ) output=false {
		var renderer = _getRenderer( name=arguments.renderer, context=arguments.context );
		var r        = "";
		var rendered = arguments.data;

		if ( renderer.isChain() ) {
			for( r in renderer.getChain() ){
				rendered = this.render( renderer=r, data=rendered, context=arguments.context );
			}

			return rendered;
		} else {
			return _getColdbox().renderViewlet( event=renderer.getViewlet(), args={ data=arguments.data } );
		}
	}

	public string function renderField(
		  required string  object
		, required string  property
		, required string  data
		,          string  context  = "default"
		,          boolean editable = false
		,          string  recordId = ""

	) output=false {
		var renderer = _getRendererForPresideObjectProperty( arguments.object, arguments.property );
		var rendered = "";

		if ( rendererExists( renderer ) ) {
			rendered = this.render(
				  renderer = renderer
				, data     = arguments.data
				, context  = arguments.context
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
	) output=false {

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

	public array function listRenderers() output=false {
		var renderers = StructKeyArray( _getRenderers() );
		ArraySort( renderers, "textnocase" );
		return renderers;
	}

	public boolean function rendererExists( required string name, string context="default" ) output=false {
		var cache     = _getCache();
		var cacheKey  = "rendererExists: " & arguments.name & " in context: " & arguments.context;
		var exists    = cache.get( cacheKey );

		if ( not IsNull( exists ) ) {
			return exists;
		}

		var renderers = _getRenderers();
		var cbProxy   = _getColdbox();

		exists = false;
		if ( StructKeyExists( renderers, arguments.name ) ) {
			if ( not StructKeyExists( renderers[ arguments.name ], arguments.context ) ) {
				if ( StructKeyExists( renderers[ arguments.name ], "default" ) ) {
					exists = true;
				}
			} else {
				exists = true;
			}
		}

		if ( not exists ) {
			exists = cbProxy.viewletExists( event=_getConventionBasedViewletName( renderer=arguments.name, context=arguments.context ) )
		    or cbProxy.viewletExists( event=_getConventionBasedViewletName( renderer=arguments.name, context="default" ) );
		}

		cache.set( cacheKey, exists );

		return exists;
	}

	public void function registerRenderer( required string name, string context="default", string viewlet="", array chain=[] ) output=false {
		var renderers = _getRenderers();

		if ( not StructKeyExists( renderers, arguments.name ) ) {
			renderers[ arguments.name ] = {};
		}

		renderers[ arguments.name ][ arguments.context ] = new ContentRenderer( viewlet=arguments.viewlet, chain=arguments.chain );

		return;
	}

	public string function getRendererForField( required struct fieldAttributes ){
		// easy, the field has explicitly defined a renderer
		if ( Len( Trim( fieldAttributes.renderer ?: "" ) ) ) {
			return Trim( fieldAttributes.renderer );
		}

		// just the plain old type?!
		if ( StructKeyExists( fieldAttributes, "type" ) ) {
			switch( fieldAttributes.type ){
				case "date":
					if ( StructKeyExists( fieldAttributes, "dbType" ) and ListFindNoCase( "timestamp,datetime", fieldAttributes.dbType ) ) {
						return "datetime";
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

// PRIVATE HELPERS
	private ContentRenderer function _getRenderer( required string name, required string context ) output=false {
		var renderers            = _getRenderers();
		var cbProxy              = _getColdbox();
		var conventionsBasedName = "";

		if ( StructKeyExists( renderers, arguments.name ) ) {
			if ( StructKeyExists( renderers[ arguments.name ], arguments.context ) ) {
				return renderers[ arguments.name ][ arguments.context ];
			}
			if ( StructKeyExists( renderers[ arguments.name ], "default" ) ) {
				return renderers[ arguments.name ].default;
			}
		}

		conventionsBasedName = _getConventionBasedViewletName( arguments.name, arguments.context );
		if ( cbProxy.viewletExists( conventionsBasedName ) ) {
			registerRenderer( arguments.name, arguments.context, conventionsBasedName );
			return new ContentRenderer( viewlet=conventionsBasedName, chain=[] );
		}
		conventionsBasedName = _getConventionBasedViewletName( arguments.name, "default" );
		if ( cbProxy.viewletExists( conventionsBasedName ) ) {
			registerRenderer( arguments.name, arguments.context, conventionsBasedName );
			return new ContentRenderer( viewlet=conventionsBasedName, chain=[] );
		}

		if ( StructKeyExists( renderers, arguments.name ) ) {
			throw(
				  type    = "Renderer.MissingDefaultContext"
				, message = "The renderer, [#arguments.name#], has neither a [default] context or a [#arguments.context#] context"
			);
		}

		throw(
			  type    = "Renderer.MissingRenderer"
			, message = "The renderer, [#arguments.name#], is not registered with the Preside rendering service"
		);
	}

	private string function _getConventionBasedViewletName( required string renderer, required string context ) output=false {
		return "renderers.content.#arguments.renderer#.#arguments.context#";
	}

	private string function _getRendererForPresideObjectProperty( required string objectName, required string property ) output=false {
		var cacheKey = "rendererFor: #arguments.objectName#.#arguments.property#";
		var cache    = _getCache();
		var renderer = cache.get( cacheKey );

		if ( not IsNull( renderer ) ) {
			return renderer;
		}

		var field = _getPresideObjectService().getObjectProperty(
			  objectName   = arguments.objectName
			, propertyName = arguments.property
		);
		renderer = getRendererForField( fieldAttributes=field.getMemento() );

		cache.set( cacheKey, renderer );

		return renderer;
	}

	private string function _getControlForPresideObjectProperty( required string objectName, required string property ) output=false {
		var cacheKey = "controlFor: #arguments.objectName#.#arguments.property#";
		var cache    = _getCache();
		var control  = cache.get( cacheKey );

		if ( not IsNull( control ) ) {
			return control;
		}

		var poService = _getPresideObjectService();
		var field     = poService.getObjectProperty(
			  objectName   = arguments.objectName
			, propertyName = arguments.property
		);

		control = poService.getDefaultFormControlForPropertyAttributes( argumentCollection = field.getMemento() );

		cache.set( cacheKey, control );

		return control;
	}


// GETTERS AND SETTERS
	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}
	private any function _getCache() output=false {
		return _cache;
	}
	private void function _setCache( required any cache ) output=false {
		_cache = arguments.cache;
	}

	private struct function _getRenderers() output=false {
		return _renderers;
	}
	private void function _setRenderers( required struct renderers ) output=false {
		_renderers = arguments.renderers;
	}
}