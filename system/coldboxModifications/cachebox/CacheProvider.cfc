component output=false extends="coldbox.system.cache.providers.CacheBoxColdBoxProvider" {

	variables._requestKey = "__cacheboxRequestCache";

	public any function clearMulti( required any keys, string prefix="" ) output=false {
		var result = {};
		var prefx  = Trim( arguments.prefix );
		var kys    = IsSimpleValue( arguments.keys ) ? ListToArray( arguments.keys ) : arguments.keys;

		request[ _requestKey ] = request[ _requestKey ] ?: {};

		for( var key in kys ){
			result[ prefx & key ] = clear( prefx & key );
			request[ _requestKey ].delete( prefx & key );
		}

		return result;
	}

	public boolean function clearQuiet( required any objectKey ) output=false {
		request[ _requestKey ] = request[ _requestKey ] ?: {};
		request[ _requestKey ].delete( arguments.objectKey );

		return super.clearQuiet( argumentCollection=arguments );
	}

	public any function get( required any objectKey ) output=false {
		request[ _requestKey ] = request[ _requestKey ] ?: {};

		if ( !StructKeyExists( request[ _requestKey ], arguments.objectKey ) ) {
			var fromSharedCache = super.get( argumentCollection=arguments );

			if ( !IsNull( local.fromSharedCache ) ) {
				request[ _requestKey ][ arguments.objectKey ] = fromSharedCache;
			}
		}

		return request[ _requestKey ][ arguments.objectKey ] ?: NullValue();
	}

	public any function set(
		  required any    objectKey
		, required any    object
		,          any    timeout           = ""
		,          any    lastAccessTimeout = ""
		,          struct extra             = {}
	) {
		setQuiet( arguments.objectKey, arguments.object, arguments.timeout, arguments.lastAccessTimeout );

		return true;
	}

	private any function locateObjectStore( string store ) {
		if ( fileExists( expandPath("/preside/system/coldboxModifications/cachebox/store/#arguments.store#.cfc") ) ) {
			return "preside.system.coldboxModifications.cachebox.store.#arguments.store#";
		}
		if( fileExists( expandPath("/coldbox/system/cache/store/#arguments.store#.cfc") ) ){
			return "coldbox.system.cache.store.#arguments.store#";
		}

		return arguments.store;
	}
}