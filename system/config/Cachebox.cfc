component {

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
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 120
						, objectDefaultLastAccessTimeout = 30
						, useLastAccessTimeouts          = true
						, reapFrequency                  = 2
						, freeMemoryPercentageThreshold  = 0
						, evictionPolicy                 = "LFU"
						, evictCount                     = 2
						, maxObjects                     = 300
						, objectStore                    = "ConcurrentStore"
					}
				},

				PresideSystemCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 60
						, evictionPolicy                 = "LFU"
						, evictCount                     = 1
						, maxObjects                     = 3000
						, objectStore                    = "ConcurrentStore"
					}
				},

				DefaultQueryCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 20
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 5
						, evictionPolicy                 = "LFU"
						, evictCount                     = 50
						, maxObjects                     = 1000
						, objectStore                    = "ConcurrentStore"
					}
				},

				PermissionsCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 120
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 5
						, evictionPolicy                 = "LFU"
						, evictCount                     = 20
						, maxObjects                     = 100
						, objectStore                    = "ConcurrentStore"
					}
				},

				WebsitePermissionsCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 20
						, objectDefaultLastAccessTimeout = 20
						, useLastAccessTimeouts          = true
						, reapFrequency                  = 5
						, evictionPolicy                 = "LFU"
						, evictCount                     = 50
						, maxObjects                     = 500
						, objectStore                    = "ConcurrentStore"
					}
				},

				PresideObjectViewCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 10
						, evictionPolicy                 = "LFU"
						, evictCount                     = 10
						, maxObjects                     = 200
						, objectStore                    = "ConcurrentStore"
					}
				},

				LabelRendererCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 10
						, evictionPolicy                 = "LFU"
						, evictCount                     = 10
						, maxObjects                     = 200
						, objectStore                    = "ConcurrentStore"
					}
				},

				PresidePageCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 1200
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 20
						, freeMemoryPercentageThreshold  = 0
						, evictionPolicy                 = "LFU"
						, evictCount                     = 200
						, maxObjects                     = 2000
						, objectStore                    = "ConcurrentStore"
					}
				},

				rulesEngineExpressionCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 0
						, evictionPolicy                 = "LFU"
						, evictCount                     = 0
						, maxObjects                     = 0
						, objectStore                    = "ConcurrentStore"
					}
				},

				ImpersonationCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 5
						, objectDefaultLastAccessTimeout = 5
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 120
						, evictionPolicy                 = "LFU"
						, evictCount                     = 10
						, maxObjects                     = 10
						, objectStore                    = "ConcurrentStore"
					}
				},

				renderedAssetCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 120
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 120
						, evictionPolicy                 = "LFU"
						, evictCount                     = 2000
						, maxObjects                     = 10000
						, objectStore                    = "ConcurrentStore"
					}
				}
			}
		};
	}
}