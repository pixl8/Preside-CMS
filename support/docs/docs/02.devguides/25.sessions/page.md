---
id: sessionmanagement
title: Session management and stateless requests
---

# Session management

All session management in the core platform is handled by the [SessionStorage ColdBox plugin](http://wiki.coldbox.org/wiki/Plugins:SessionStorage.cfm). Your applications and extensions should also _always_ use this plugin when needing to store data against the session, rather than use the session scope directly.

## Accessing the session storage plugin

### In a handler

```luceescript
property name="sessionStorage" inject="coldbox:plugin:sessionStorage";

// or...

var sessionStorage = getPlugin( "sessionStorage" );

```

### In a service

```luceescript
/**
 * @singleton
 * @presideservice
 *
 */
component {
	
	/**
	 * @sessionStorage.inject coldbox:plugin:sessionStorage
	 *
	 */
	public any function init( required any sessionStorage ) {
		// set the session storage plugin to some local variable for later use
	}

}
```

Or

```luceescript
/**
 * @singleton
 * @presideservice
 *
 */
component {
	
	property name="sessionStorage" inject="coldbox:plugin:sessionStorage";

	// ...

}
```

## Using the session storage plugin

See the [ColdBox wiki for full documentation](http://wiki.coldbox.org/wiki/Plugins:SessionStorage.cfm).

# Stateless requests

As of v10.5.0, PresideCMS comes with some configuration options for automatically serving "stateless" requests which turn off session management and ensure that no cookies are set. This is useful for things like [[restframework|REST API requests]], scheduled tasks, and known bots and spiders.

## Default implementation

The default implementation will flag the following requests as being stateless and not create sessions or cookies for them:

* Any request path starting with `/api/` (the default pattern for the [[restframework|REST Framework]])
* Lucee Scheduled Task requests (matching user agent 'CFSCHEDULE')
* Requests flagged as bot or spider requests, matched on user agent

## Overriding the default implementation

### Method 1: SetupApplication()

In your site's `Application.cfc`, you can pass arrays of user agent and URL regex patterns to the `setupApplication()` method that will be treated as stateless. These will _override_ the core defaults. For example:

```luceescript
component extends="preside.system.Bootstrap" {
	
	super.setupApplication(
		  id                         = "my-site"
		, statelessUrlPatterns       = [ "https?://static\..*" ]
		, statelessUserAgentPatterns = [ "CFSCHEDULE", "bot\b", "spider\b" ]
	);

}
```

In the example above the `statelessUrlPatterns` argument gives a single URL pattern that states that any URL with a "static." sub-domain will be treated as stateless. The `statelessUserAgentPatterns` argument, specifies that the "CFSCHEDULE" user agent, along with some simple bot patterns will be treated as stateless requests.

### Method 2: isStatelessRequest()

In your site's `Application.cfc`, implement the `isStatelessRequest( fullUrl )` method that must return `true` for stateless requests and `false` otherwise. For example:

```luceescript
component extends="preside.system.Bootstrap" {
	
	super.setupApplication(
		id = "my-site"
	);

	private boolean function isStatelessRequest( required string fullUrl ) {
		var isStateless = false;

		// add some custom logic to define stateless requests
		// ...

		return isStateless;
	}

}
```

You could also use a combination of both methods:

```luceescript
component extends="preside.system.Bootstrap" {
	
	// set custom URL and user agent patterns
	super.setupApplication(
		  id                         = "my-site"
		, statelessUrlPatterns       = [ "https?://static\..*" ]
		, statelessUserAgentPatterns = [ "CFSCHEDULE", "bot\b", "spider\b" ]
	);

	private boolean function isStatelessRequest( required string fullUrl ) {
		// use the core `isStatelessRequest()` method to act
		// on the URL and User agent patterns
		var isStateless = super.isStatelessRequest( argumentCollection=arguments );

		// your own extended logic
		if ( !isStateless ) {
			// add some further custom logic to define stateless requests
			// ...
			
		} 

		return isStateless;
	}

}
```