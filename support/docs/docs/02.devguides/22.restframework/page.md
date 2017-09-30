---
id: restframework
title: REST framework
---

>>>> As of v10.4.0, the REST framework should be considered BETA. We expect details may change in upcoming releases, though we do not expect those changes to be dramatic or breaking.

## Introduction

PresideCMS provides a framework for developing REST APIs that work inline and seamlessly with the rest of the ecosystem. It has taken inspiration from the [Taffy REST Framework](http://taffy.io/) by Adam Tuttle, and follows several of its patterns.

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

		restResponse.setData( QueryToArray( records ) )
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

The entire URL path for routing a REST request to a resource will be made up of three parts:

1. The configured REST path that tells PresideCMS that this is a REST request. The default is `/api`.
2. The path to the specific API that the resource lives under, i.e. the folder structure beneath `/handlers/rest-apis`
3. The path that will match the specific resource

For example, if your resource lived at `/handlers/rest-apis/myapi/v1/Page.cfc` and defined the `@restUri` pattern as `/pages/,/pages/{slug}/{pageid}/`, it would match the following URL paths:

```
/api/myapi/v1/pages/
/api/myapi/v1/pages/some-slug/359860837568/
```

>>>>>> You can configure the path that the framework uses to recognize rest requests by setting the `settings.rest.path` variable in your site's `Config.cfc` file. e.g. `settings.rest.path = "/rest";`.

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

		restResponse.noData().setStatus( 200, "OK" );
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

		restResponse.noData().setStatus( 200, "OK" );
	}
}
```

## Accepting arguments

Because your REST API resources are defined as ColdBox handlers, your handler actions will always receive the usual `event`, `rc` and `prc` arguments.

### REST Request and Response objects

In addition to the standard ColdBox arguments, the REST framework provides your handler action with `restRequest` and `restResponse` arguments. You can use the `restResponse` object to set data, mime type, renderer, status code and HTTP headers for the response of the REST request. The `restRequest` argument can be used to discover information about the request, and to prematurely end the request with `restRequest.finish()`.

See the reference docs for [[api-presiderestrequest]] and [[api-presiderestresponse]] for full details.


```luceescript
/**
 * @restUri /events/
 *
 */
component {
	private void function get() {
		restResponse.setError(
			  errorCode = 501
			, title     = "Not implemented"
			, message   = "The /events/ GET api has not yet been implemented."
		);
	}
}
```

>>>>>> We prefer not to include the `event`, `rc`, `prc`, `restRequest` and `restResponse` arguments in the function *definition* to help with readability.

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

Any additional configuration of the REST APIs can be made in your site's `Config.cfc` file. There is a core settings structure for REST that looks like:

```luceescript
settings.rest = {
	  path        = "/api"
	, corsEnabled = false
	, apis        = {}
};
```

Additional settings can be defined either globally, or per API. Currently there is only a single setting, `corsEnabled` which is turned off by default. An example of turning CORS on globally would look like this:

```luceescript
settings.rest.corsEnabled = true
```

Or, to turn it on only for a specific API:

```luceescript
settings.rest.apis[ "/myapi/v2" ] = { corsEnabled=true };
```

## Basic caching

The framework automatically adds `ETag` response headers for GET and HEAD REST requests. These are a simple MD5 hash of the serialized response body. In addition, if the REST request includes a `If-None-Match` request header whose value matches the generated `ETag`, the framework will set an empty response body and set the status of the response to `304 Not modified`.

More advanced caching can be achieved using the CacheBox framework that is built in to ColdBox (and therefore PresideCMS). See the [ColdBox docs](http://wiki.coldbox.org/wiki/CacheBox.cfm) for further details.

## HEAD requests

The framework deals with HEAD requests for you, without you needing to implement a resource handler action for the verb. Simply, when responding to a HEAD request, the system will call the GET action for your resource and empty the body data before rendering the response.

## CORS support

[CORS (Cross-Origin Request Sharing)](http://www.w3.org/TR/cors/) is used to validate that a resource can be used by a system from another origin. This is relevant for browser based JavaScript requests to your API where the requesting page resides at a domain that differs to that of the API.

Before requesting the remote resource fully, a browser will send a "pre-flight" request using the `OPTIONS` HTTP Method along with headers to describe the intentions of the upcoming request. The PresideCMS Rest framework detects these requests for you and responds appropriately based on:

1. Whether or not CORS is enabled for the API (currently, we only allow enabling or disabling CORS globally for all domains)
2. Whether or not the matching resource supplies a method for responding to the given HTTP Method

If the framework detects an `OPTIONS` request without the prerequisite CORS headers, it will respond with a `400 Bad request` status. If the request is valid, but CORS disallowed for either of the reasons above, a `403 Forbidden` status will be returned. Finally, if the request is valid and the CORS request allowed, a `200 OK` status will be returned, along with the relevant `Access-Control` response headers to inform the calling system that the CORS request is valid.

## Interception points

Your application can listen into several core interception points to enhance the features of the REST platform, e.g. to implement custom authentication. See the [ColdBox Interceptor's documentation](http://wiki.coldbox.org/wiki/Interceptors.cfm) for detailed documentation on interceptors.

For example, an interceptor that listens for the `onUnsupportedRestMethod` interception point and changes the REST response to something other than the default:

```luceescript
component extends="coldbox.system.Interceptor" {

	public void function configure() {}

	public void function onUnsupportedRestMethod( event, interceptData ) {
		var response = interceptData.restResponse;

		response.setStatus( 405, "This is not the method you are looking for" )
		        .setBody( "nope" )
		        .setRenderer( "plain" )
		        .setMimeType( "text/plain" );
	}
}
```

The Interception points are:

### onRestRequest

Fired at the beginning of a REST request. Takes `restRequest` and `restResponse` objects as arguments.

### onRestError

Fired whenever an unhandled exception occurs during execution of the request. Takes `error`, `restRequest` and `restResponse` objects as arguments.

### onMissingRestResource

Fired when no resource matches the incoming URL Path. Takes `restRequest` and `restResponse` objects as arguments.

### onUnsupportedRestMethod

Fired when the matched resource does not support the used HTTP Method. Takes `restRequest` and `restResponse` objects as arguments.

### preInvokeRestResource

Fired before the resource's handler action is called. Takes `args` structure, and `restRequest` and `restResponse` objects as arguments. The `args` structure are the arguments that will be passed to the resource's handler action.

### postInvokeRestResource

Fired after the resource's handler action is called. Takes `args` structure, and `restRequest` and `restResponse` objects as arguments. The `args` structure represents the arguments that were passed to the resource's handler action.