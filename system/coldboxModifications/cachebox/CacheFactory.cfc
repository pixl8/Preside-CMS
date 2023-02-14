/**
 * Preside override to prevent reapAll
 * from happening by default each request.
 *
 */
component extends="coldbox.system.cache.CacheFactory" {

	CacheFactory function reapAll( boolean force=false ){
		if ( arguments.force ) {
			super.reapAll();
		}

		return this;
	}
}