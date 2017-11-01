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
						, objectStore                    = "ConcurrentSoftReferenceStore"
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
						, maxObjects                     = 300
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
						, objectStore                    = "ConcurrentSoftReferenceStore"
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
						, objectStore                    = "ConcurrentSoftReferenceStore"
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
						, objectStore                    = "ConcurrentSoftReferenceStore"
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
						, objectStore                    = "ConcurrentSoftReferenceStore"
					}
				},

				ViewletExistsCache = {
					  provider   = "preside.system.coldboxModifications.cachebox.CacheProvider"
					, properties = {
						  objectDefaultTimeout           = 0
						, objectDefaultLastAccessTimeout = 0
						, useLastAccessTimeouts          = false
						, reapFrequency                  = 10
						, evictionPolicy                 = "LFU"
						, evictCount                     = 200
						, maxObjects                     = 1000
						, objectStore                    = "ConcurrentSoftReferenceStore"
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
						, objectStore                    = "ConcurrentSoftReferenceStore"
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
				}
			}
		};
	}
}