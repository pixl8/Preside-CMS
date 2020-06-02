component {

	public any function init(
		  required any state
		, required any logbox
		, required any controller
	) {
		instance = {};

		instance.pool 	     = [];
		instance.poolSize    = 0;
		instance.state 	     = arguments.state;
		instance.controller  = arguments.controller;
		instance.metadataMap = structnew();
		instance.utility     = createObject("component","coldbox.system.core.util.Util");
		instance.uuidHelper	 = createobject("java", "java.util.UUID");
		instance.log         = arguments.logbox.getLogger( this );

		return this;
	}

	public any function register( required string interceptorKey, required any interceptor, struct interceptorMd ) {
		ArrayAppend( instance.pool, { key=arguments.interceptorKey, target=arguments.interceptor } );

		instance.poolSize = ArrayLen( instance.pool );

		instance.metadataMap[ arguments.interceptorKey ] = arguments.interceptorMd;
	}

	public any function unregister( required string interceptorKey ) {
		var unregistered = false;

		for( var i=instance.pool.len(); i>0; i-- ) {
			if ( instance.pool[ i ].key == arguments.interceptorKey ) {
				ArrayDeleteAt( instance.pool, i );
				unregistered = true;
			}
		}

		StructDelete( instance.metadataMap, arguments.interceptorKey );
		instance.poolSize = ArrayLen( instance.pool );

		return unregistered;
	}

	public any function process(
		  required any     event
		, required any     interceptData
		, required any     buffer
		,          boolean async            = false
		,          boolean asyncAll         = false
		,          boolean asyncAllJoin     = true
		,          string  asyncPriority    = "NORMAL"
		,          numeric asyncJoinTimeout = 0
	) {
		if ( arguments.async && !instance.utility.inThread() ) {
			return processAsync(
				  event         = arguments.event
				, interceptData = arguments.interceptData
				, asyncPriority = arguments.asyncPriority
				, buffer        = arguments.buffer
			);
		} else if ( arguments.asyncAll AND NOT instance.utility.inThread() ) {
			return processAsyncAll( argumentCollection=arguments );
		} else {
			processSync( event=arguments.event, interceptData=arguments.interceptData, buffer=arguments.buffer );
		}
	}

	public any function getInterceptor( required string interceptorKey ) {
		var i = 0;
		for( i=1; i<=instance.poolSize; i++ ) {
			if ( instance.pool[ i ].key == arguments.interceptorKey ) {
				return instance.pool[ i ].target;
			}
		}
	}

	public string function getState() {
		return instance.state;
	}

	public boolean function exists( required string interceptorKey ) {
		return StructKeyExists( instance.metadataMap, arguments.interceptorKey );
	}

	public any function getMetadataMap( string interceptorKey ) {
		if ( StructKeyExists( arguments, "interceptorKey" ) ) {
			return instance.metadataMap[ arguments.interceptorKey ];
		}

		return instance.metadataMap;
	}

	public any function getInterceptors() {
		return instance.pool;
	}

	public boolean function isExecutable( event, targetKey ) {
		var iData = instance.metadataMap[ arguments.targetKey ];

		if( Len( iData.eventPattern ) && !ReFindNoCase( iData.eventPattern, arguments.event.getCurrentEvent() ) ) {
			if( instance.log.canDebug() ){
				instance.log.debug("Interceptor '#getMetadata( arguments.target ).name#' did NOT fire in chain: '#getState()#' due to event pattern mismatch: #iData.eventPattern#.");
			}

			return false;
		}

		return true;
	}

// PRIVATE HELPERS
	private any function processSync(
		  any event
		, any interceptData
		, any buffer
	){
		var i = 0;

		if ( instance.log.canDebug() ){
			instance.log.debug( "Starting '#getState()#' chain with #structCount( interceptors )# interceptors" );
		}

		for( i=1; i<=instance.poolSize; i++ ){
			var key             = instance.pool[ i ].key;
			var thisInterceptor = instance.pool[ i ].target;

			if( isExecutable( arguments.event, key ) ){
				if ( instance.metadataMap[ key ].async && !instance.utility.inThread() ){
					invokerAsync(
						  event          = arguments.event
						, interceptData  = arguments.interceptData
						, interceptorKey = key
						, asyncPriority  = instance.metadataMap[ key ].asyncPriority
						, buffer         = arguments.buffer
					);
				} else if(
					invoker(
						  interceptor    = thisInterceptor
						, event          = arguments.event
						, interceptData  = arguments.interceptData
						, interceptorKey = key
						, buffer         = arguments.buffer
					)
				){
					break;
				}
			}
		}

		if( instance.log.canDebug() ){
			instance.log.debug( "Finished '#getState()#' execution chain" );
		}
	}

	private any function processAsync(
		  any event
		, any interceptData
		, any asyncPriority
		, any buffer
	) {
		var threadName = "cbox_ichain_#replace( instance.uuidHelper.randomUUID(), "-", "", "all" )#";

		if ( instance.log.canDebug() ) {
			instance.log.debug("Threading interceptor chain: '#getState()#' with thread name: #threadName#, priority: #arguments.asyncPriority#" );
		}

		thread name          = threadName
		       action        = "run"
		       priority      = arguments.asyncPriority
		       interceptData = arguments.interceptData
		       threadName    = threadName
		       buffer        = arguments.buffer {

		    variables.processSync(
				event 			= instance.controller.getRequestService().getContext(),
				interceptData	= attributes.interceptData,
				buffer 			= attributes.buffer
			);

			if ( instance.log.canDebug() ) {
				instance.log.debug( "Finished threaded interceptor chain: #getState()# with thread name: #attributes.threadName#", thread );
			}
		}

		return cfthread[ threadName ];
    }

	private any function processAsyncAll(
    	  any event
		, any interceptData
		, any asyncAllJoin
		, any asyncPriority
		, any asyncJoinTimeout
		, any buffer
	) {
		var threadNames    = [];
		var thisThreadName = "";
		var key            = "";
		var threadData     = {};
		var threadIndex    = "";
		var i              = 0;

		if ( instance.log.canDebug() ) {
			instance.log.debug("AsyncAll interceptor chain starting for: '#getState()#' with join: #arguments.asyncAllJoin#, priority: #arguments.asyncPriority#, timeout: #arguments.asyncJoinTimeout#" );
		}

		for( i=1; i<=poolSize; i++ ){
			var key             = instance.pool[ i ].key;

			thisThreadName = "ichain_#key#_#replace( instance.uuidHelper.randomUUID(), "-", "", "all" )#";
			ArrayAppend( threadNames, thisThreadName );

			thread name          = thisThreadName
			       action        = "run"
			       priority      = arguments.asyncPriority
			       interceptData = arguments.interceptData
			       threadName    = thisThreadName
			       buffer        = arguments.buffer
			       key           = key {

				var thisInterceptor = this.getInterceptor( attributes.key );

				if( variables.isExecutable( thisInterceptor, attributes.event, attributes.key ) ){
					variables.invoker(
						interceptor 	= thisInterceptor,
						event 			= instance.controller.getRequestService().getContext(),
						interceptData 	= attributes.interceptData,
						interceptorKey 	= attributes.key,
						buffer 			= attributes.buffer
					);

					if( instance.log.canDebug() ){
						instance.log.debug( "Interceptor '#getMetadata( thisInterceptor ).name#' fired in asyncAll chain: '#this.getState()#'" );
					}
				}
			}
		}

		if ( arguments.asyncAllJoin ) {
			if ( instance.log.canDebug() ) {
				instance.log.debug("AsyncAll interceptor chain waiting for join: '#getState()#', timeout: #arguments.asyncJoinTimeout# " );
			}

			thread action="join" name=ArrayToList( threadNames ) timeout=arguments.asyncJoinTimeout;
		}

		if ( instance.log.canDebug() ) {
			instance.log.debug("AsyncAll interceptor chain ended for: '#getState()#' with join: #arguments.asyncAllJoin#, priority: #arguments.asyncPriority#, timeout: #arguments.asyncJoinTimeout#" );
		}

		for( var threadIndex in threadNames ) {
			threadData[ threadIndex ] = cfthread[ threadIndex ];
		}

		return threadData;
	}

	private boolean function invoker(
		  required any interceptor
		, required any event
		, required any interceptData
		, required any interceptorKey
		, required any buffer
	) {
		var refLocal = {};

		if ( instance.log.canDebug() ) {
			instance.log.debug( "Interception started for: '#getState()#', key: #arguments.interceptorKey#" );
		}

		refLocal.results = arguments.interceptor[ getState() ](
			  event         = arguments.event
			, interceptData = arguments.interceptData
			, buffer        = arguments.buffer
			, rc            = arguments.event.getCollection()
			, prc           = arguments.event.getPrivateCollection()
		);

		if ( instance.log.canDebug() ) {
			instance.log.debug( "Interception ended for: '#getState()#', key: #arguments.interceptorKey#" );
		}


		if ( StructKeyExists( refLocal, "results" ) && IsBoolean( refLocal.results ) ) {
			return refLocal.results;
		}

		return false;
	}

	private any function invokerAsync(
		  required any event
		, required any interceptData
		, required any interceptorKey
		, required any buffer
		,          any asyncPriority = "normal"
	) {
		var thisThreadName = "asyncInterceptor_#arguments.interceptorKey#_#replace( instance.uuidHelper.randomUUID(), "-", "", "all" )#";

		if ( instance.log.canDebug() ) {
			instance.log.debug("Async interception starting for: '#getState()#', interceptor: #arguments.interceptorKey#, priority: #arguments.asyncPriority#" );
		}

		thread name          = thisThreadName
		       action        = "run"
		       priority      = arguments.asyncPriority
		       event         = arguments.event
		       interceptData = arguments.interceptData
		       threadName    = thisThreadName
		       key           = arguments.interceptorKey
		       buffer        = arguments.buffer {

		    var interceptor = getInterceptor( attributes.interceptorKey );

		    interceptor[ this.getState() ](
		    	  event         = attributes.event
				, interceptData = attributes.interceptData
				, buffer        = attributes.buffer
				, rc            = attributes.event.getCollection()
				, prc           = attributes.event.getPrivateCollection()
		    );

			if ( instance.log.canDebug() ) {
				instance.log.debug( "Async interception ended for: '#this.getState()#', interceptor: #attributes.key#, threadName: #attributes.threadName#" );
			}
		}
	}
}