component extends="coldbox.system.web.Controller" output=false {

	public any function init() output=false {
		super.init( argumentCollection = arguments );

		services.handlerService     = new preside.system.coldboxModifications.services.HandlerService( this );
		services.interceptorService = new preside.system.coldboxModifications.services.InterceptorService( this );
		services.requestService     = new preside.system.coldboxModifications.services.RequestService( this );
		instance.wireBox            = CreateObject( "preside.system.coldboxModifications.ioc.Injector" );
	}

	public boolean function handlerExists( required string event ) output=false {
		variables._handlerExistsCache = variables._handlerExistsCache ?: {};
		if ( variables._handlerExistsCache.keyExists( arguments.event ) ) {
			return variables._handlerExistsCache[ arguments.event ];
		}

		var handlerSvc = "";
		var handler    = "";
		var action     = ListLast( arguments.event, "." );
		var exists     = false;

		try {
			handlerSvc = getHandlerService();
			handler = handlerSvc.getRegisteredHandler( event=arguments.event );

			if ( handler.getViewDispatch() ) {
				exists = false;
			} else {
				var fullEvent = handler.getFullEvent();
				if ( fullEvent != arguments.event && fullEvent != ( arguments.event & ".index" ) ) {
					exists = false;
				} else {
					handler = handlerSvc.getHandler( handler, getRequestContext() );
					handler = GetMetaData( handler );

					if ( Right( handler.fullname ?: "", Len( arguments.event ) ) eq arguments.event ) {
						action = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
					}

					exists = _actionExistsInHandler( handler, action );
				}
			}


		} catch( "HandlerService.EventHandlerNotRegisteredException" e ) {
			exists = false;
		}

		variables._handlerExistsCache[ arguments.event ] = exists;
		return exists;
	}

	public boolean function viewExists( required string view ) output=false {
		variables._viewExistsCache = variables._viewExistsCache ?: {};
		if ( variables._viewExistsCache.keyExists( arguments.view ) ) {
			return variables._viewExistsCache[ arguments.view ];
		}

		var targetView = getPlugin( "Renderer" ).locateView( ListChangeDelims( arguments.view, "/", "." ) );
		var exists     = Len( Trim( targetView ) ) and FileExists( ExpandPath( targetView & ".cfm" ) );

		variables._viewExistsCache[ arguments.view ] = exists;

		return exists;
	}

	public boolean function viewletExists( required string event ) output=false {
		return handlerExists( arguments.event ) or viewExists( arguments.event );
	}

	public any function renderViewlet(
		  required string  event
		,          struct  args          = {}
		,          boolean private       = true
		,          boolean prepostExempt = true
		,          boolean delayed       = _isViewletDelayed( arguments.event )
	) output=false {
		if ( arguments.delayed ) {
			return instance.wireBox.getInstance( "delayedViewletRendererService" ).renderDelayedViewletTag(
				  event = arguments.event
				, args  = arguments.args
			);
		}
		var result        = "";
		var view          = "";
		var handler       = arguments.event;
		var defaultAction = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );

		if ( !handlerExists( handler ) ) {
			handler = ListAppend( handler, defaultAction, "." );
		}

		if ( handlerExists( handler ) ) {
			return runEvent(
				  event          = handler
				, prepostExempt  = arguments.prepostExempt
				, private        = arguments.private
				, eventArguments = { args = arguments.args }
			);
		}

		view = ListChangeDelims( arguments.event, "/", "." );
		if ( !viewExists( view ) ) {
			view = ListAppend( view, defaultAction, "/" );
		}

		return getPlugin( "Renderer" ).renderView(
			  view = view
			, args = arguments.args
		);
	}

	public any function getRequestContext() output=false {
		return getRequestService().getContext();
	}

	public any function getSetting( required string name, boolean fwSetting=false, any defaultValue ) output=false {
		var target = arguments.fwSetting ? instance.coldboxSettings : instance.configSettings;

		if ( target.keyExists( arguments.name ) ) {
			return target[ arguments.name ];
		}

		if ( IsDefined( "target.#arguments.name#" ) ) {
			return Evaluate( "target.#arguments.name#" );
		}

		if ( StructKeyExists( arguments, "defaultValue" ) ) {
			return arguments.defaultValue;
		}

		getUtil().throwit(
			  message = "The setting #arguments.name# does not exist."
			, detail  = "FWSetting flag is #arguments.FWSetting#"
			, type    = "Controller.SettingNotFoundException"
		);
	}

// private helpers
	private boolean function _actionExistsInHandler( required struct handlerMeta, required string action ) output=false {
		if ( StructKeyExists( arguments.handlerMeta, "extends" ) and _actionExistsInHandler( arguments.handlerMeta.extends, arguments.action ) ) {
			return true;
		}

		var functions = arguments.handlerMeta.functions ?: [];

		for( var func in functions ) {
			if ( ( func.name ?: "" ) eq arguments.action ) {
				return true;
			}
		}

		return false;
	}

	private boolean function _isViewletDelayed( required string event ) {
		variables._viewletDelayedLookupCache = variables._viewletDelayedLookupCache ?: {};

		if ( _viewletDelayedLookupCache.keyExists( arguments.event ) ) {
			return _viewletDelayedLookupCache[ arguments.event ];
		}

		var isDelayed     = false;
		var defaultAction = getSetting( name="EventAction", fwSetting=true, defaultValue="index" );
		var handler       = arguments.event;

		if ( !handlerExists( handler ) ) {
			handler = ListAppend( handler, defaultAction, "." );
		}

		if ( handlerExists( handler ) && instance.wirebox.getInstance( "featureService" ).isFeatureEnabled( "fullPageCaching" ) ) {
			var action     = ListLast( handler, "." );
			var handlerSvc = getHandlerService();

			handler = handlerSvc.getRegisteredHandler( event=handler );
			handler = handlerSvc.getHandler( handler, getRequestContext() );
			handler = GetMetaData( handler );

			var functions = handler.functions ?: [];

			for( var func in functions ) {
				if ( ( func.name ?: "" ) == action ) {
					var cacheable = func.cacheable ?: "";

					isDelayed = IsBoolean( func.cacheable ?: "" ) && !func.cacheable;
					break;
				}
			}
		}

		_viewletDelayedLookupCache[ arguments.event ] = isDelayed;

		return isDelayed;
	}
}