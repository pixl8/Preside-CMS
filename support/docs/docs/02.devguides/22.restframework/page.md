---
id: restframework
title: REST Framework
---

As of v10.4.0, PresideCMS provides a framework for developing REST APIs that work inline and seamlessly with the rest of the ecosystem. It has taken inspiration from the [Taffy REST Framework](http://taffy.io/) by Adam Tuttle, and follows several of its patterns.

The current version of the framework provides you with the conventions, services and routing layer to help you easily author your own REST APIs; further tooling such as documentation generation and user management are planned for future releases. 

>>> The documentation here will not attempt to teach the ins and outs of RESTful APIs; rather document how PresideCMS implements RESTful concepts. We can highly recommend Adam Tuttle's book, [REST Assured](http://restassuredbook.com/) as a primer and go-to resource for authoring REST APIs.

## APIs and Resources

Creating a new REST API in PresideCMS is a case of creating a directory containing coldbox handler CFCs. Each handler represents a resource in your API. These APIs and resources must all live under your application's `/handlers/rest-apis/` folder. For example:

```
/application/handlers/rest-apis
    /my-cool-api
        /v1
            SomeResource.cfc
```

The structure above defines a resource, `SomeResource`, beneath the `/my-cool-api/v1` API.

## Defining a resource

Resource CFCs are simple ColdBox handlers with some additional annotations to define how they should work within the REST API. An example:

```luceescript
/**
 * @restUri /someresource/{variable}/{variable2}/
 *
 */
component {
	
	property name="pageDao" inject="presidecms:object:page";

	private void function get( required string variable, required string variable2 ) {
		var records = someDao.selectData(
			  selectFields = [ "id", "title" ]
			, savedFilters = [ "livePages" ]
		);

		response.setData( QueryToArray( records ) )
		        .setStatus( 200, "Awesome" )
		        .setHeader( "X-Rocking", true );
	}

	private void function post( required string variable, required string variable2 ) {
		// ...
	}

	/**
	 * @restVerb push
	 *
	 */
	private void function anotherNameForPush( required string variable, required string variable2 ) {
		// ...
	}

	// etc.
}

```

## Routing and the REST URI definition

The `@restUri` annotation defines URL patterns that will be matched by this resource. It can optionally contain wildcards that map to variable names indicated by curly braces `{somevariable}`. Individual patterns are separated with a comma.

The entire URL path for routing a REST request to this resource will be made up of three parts:

1. The configured REST path that tells PresideCMS that this is a REST request. The default is `/api`.
2. The path to the specific API that the resource lives under, i.e. the folder structure beneath `/handlers/rest-apis`
3. The path that will match the specific resource

For example, if your resource lived at `/handlers/rest-apis/myapi/v1/Page.cfc` and defined the `@restUri` pattern as `/pages/,/pages/{slug}/{pageid}/`, it would match the following URL paths:

```
/api/myapi/v1/pages/
/api/myapi/v1/pages/some-slug/359860837568/
```

The `/api` part of the URL path tells PresideCMS that this is a REST API request. This is configurable in `Config.cfc` with the `settings.rest.path` variable, e.g. `settings.rest.path = "/rest"`.

Next, `/myapi/v1` maps to the API that the resource lives under.

Finally, `/pages/some-slug/359860837568/` and `/pages/` both match patterns defined in the `@restUri` annotation.

## Mapping HTTP Methods (Verbs) to resource handler actions

By providing methods on your resource CFC that match the names of HTTP Methods, you can route a request to a specific function based on the HTTP method used by the request. For example, to handle a request to your resources URI using the HTTP DELETE method, you would implement a `delete` handler action:

```luceescript
/**
 * @restUri /blogcategories/,/blogcategories/{slug}/{id}/
 *
 */
component {
	
	property name="blogCategoryDao" inject="presidecms:object:blog_category";

	private void function delete( required string id ) {
		blogCategoryDao.deleteData( id=arguments.id );

		response.noData().setStatus( 200, "OK" );
	}
}
```

### Using different method names

If you prefer, or need, to use different method names, you can map HTTP methods to your handler actions with the `@restVerb` annotation against the handler action itself. e.g. here we map the `deleteCategory` method to the `DELETE` verb:

```luceescript
/**
 * @restUri /blogcategories/,/blogcategories/{slug}/{id}/
 *
 */
component {
	
	property name="blogCategoryDao" inject="presidecms:object:blog_category";

	/**
	 * @restVerb DELETE
	 *
	 */
	private void function deleteCategory( required string id ) {
		blogCategoryDao.deleteData( id=arguments.id );

		response.noData().setStatus( 200, "OK" );
	}
}
```

## Accepting arguments

Because your REST API resources are defined as ColdBox handlers, your handler actions will always receive the usual `event`, `rc` and `prc` arguments. In addition, the REST framework provides your handler action with a `response` argument that is an instance of the [[api-presiderestresponse]] object. You can use the `response` object to set data, mime type, renderer, status code and HTTP headers for the response of the REST request. See [[api-presiderestresponse]] for a full reference. e.g.

```luceescript
/**
 * @restUri /events/
 *
 */
component {
	private void function get() {
		response.setError( 
			  errorCode = 501
			, title     = "Not implemented"
			, message   = "The /events/ GET api has not yet been implemented." 
		);
	}
}
```

>>>>>> we prefer not to include the event, rc, prc and response arguments in the function definition to help readability.

### REST URI Tokens

If your resource defines a URI mapping that includes tokens, these will also be passed to your handler actions when available, for instance:

```luceescript
/**
 * @restUri /events/,/events/{id}/
 *
 */
component {
	
	// here, the 'id' argument is automatically 
	// passed to the action when it is present
	// in the rest URI
	private void function get( string id="" ) {
		// ...
	}
}
```

### URL Parameters

Finally, any query string or POST parameters will also be available as individual arguments (in addition to being available in `rc`). This will help future development in the API where we would like to automatically raise friendly errors for missing parameters, etc.

For example:

```luceescript
/**
 * @restUri /events/,/events/{id}/
 *
 */
component {
	
	private void function get(
		  string  id       = ""
		, numeric page     = 1
		, numeric pageSize = 50
	) {
		// here we expect URLs like /events/?page=3&pageSize=10
		// or /events/34583745/
	}
}
```

## Configuring your APIs

## Interception points

