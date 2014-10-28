component output=false {
	function configure(){
		cacheBox = {
			// core coldbox cache
			defaultCache = {
				  objectDefaultTimeout           = 120
				, objectDefaultLastAccessTimeout = 30
				, useLastAccessTimeouts          = true
				, reapFrequency                  = 2
				, freeMemoryPercentageThreshold  = 0
				, evictionPolicy                 = "LFU"
				, evictCount                     = 1
				, maxObjects                     = 300
				, objectStore                    = "ConcurrentStore"
				, coldboxEnabled                 = true
			},

			// custom caches
			caches = {
				// named cache for all coldbox event and view template caching
				template = {
					  provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
					, properties = {
						  objectDefaultTimeout           = 120
						, objectDefaultLastAccessTimeout = 30
						, useLastAccessTimeouts          = true
						, reapFrequency                  = 2
						, freeMemoryPercentageThreshold  = 0
						, evictionPolicy                 = "LFU"
						, evictCount                     = 2
						, maxObjects                     = 300
						, objectStore                    = "ConcurrentSoftReferenceStore"
					}
				},

				SystemCache = {
					  provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 60
						, evictionPolicy                 = "LFU"
						, evictCount                     = 1
						, maxObjects                     = 300
						, objectStore                    = "ConcurrentStore"
					}
				},

				DefaultQueryCache = {
					  provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
					, properties = {
						  objectDefaultTimeout           = 20
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 5
						, evictionPolicy                 = "LFU"
						, evictCount                     = 50
						, maxObjects                     = 1000
						, objectStore                    = "ConcurrentSoftReferenceStore"
					}
				},

				PermissionsCache = {
					  provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
					, properties = {
						  objectDefaultTimeout           = 120
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 5
						, evictionPolicy                 = "LFU"
						, evictCount                     = 20
						, maxObjects                     = 100
						, objectStore                    = "ConcurrentSoftReferenceStore"
					}
				},

				WebsitePermissionsCache = {
					  provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
					, properties = {
						  objectDefaultTimeout           = 20
						, objectDefaultLastAccessTimeout = 20
						, useLastAccessTimeouts          = true
						, reapFrequency                  = 5
						, evictionPolicy                 = "LFU"
						, evictCount                     = 50
						, maxObjects                     = 500
						, objectStore                    = "ConcurrentSoftReferenceStore"
					}
				},

				PresideObjectViewCache = {
					  provider   = "coldbox.system.cache.providers.CacheBoxColdBoxProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 10
						, evictionPolicy                 = "LFU"
						, evictCount                     = 10
						, maxObjects                     = 200
						, objectStore                    = "ConcurrentSoftReferenceStore"
					}
				}
			}
		};
	}
}