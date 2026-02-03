component {

	function configure( cachebox ){
		/*
		 * Add your own custom cachebox configurations here
		 */

		arguments.cachebox.caches.myAppExtensionCache = {
			  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
			, properties = {
				  objectDefaultTimeout           = 20
				, objectDefaultLastAccessTimeout = 0
				, useLastAccessTimeouts          = false
				, reapFrequency                  = 5
				, evictionPolicy                 = "LFU"
				, evictCount                     = 200
				, maxObjects                     = 1000
				, objectStore                    = "ConcurrentStore"
			}
		};
	}

}