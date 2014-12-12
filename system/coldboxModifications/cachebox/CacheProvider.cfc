component output=false extends="coldbox.system.cache.providers.CacheBoxColdBoxProvider" {

	public any function clearMulti( required any keys, string prefix="" ) output=false {
		var result = {};
		var prefx  = Trim( arguments.prefix );
		var kys    = IsSimpleValue( arguments.keys ) ? ListToArray( arguments.keys ) : arguments.keys;

		for( var key in kys ){
			result[ prefx & key ] = clear( prefx & key );
		}

		return result;
	}
}