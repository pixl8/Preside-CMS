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

	public any function get( required string objectKey ) output=false {
		request[ _requestKey ] = request[ _requestKey ] ?: {};

		if ( !request[ _requestKey ].keyExists( arguments.objectKey ) ) {
			var fromSharedCache = super.get( argumentCollection=arguments );

			if ( !IsNull( fromSharedCache ) ) {
				request[ _requestKey ][ arguments.objectKey ] = fromSharedCache;
			}
		}

		return request[ _requestKey ][ arguments.objectKey ] ?: NullValue();
	}
}