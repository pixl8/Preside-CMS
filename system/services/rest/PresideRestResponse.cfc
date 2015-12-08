/**
 * Object to represent a REST response. Used in REST requests (see [[preside-rest-platform]]).
 *
 * @autodoc true
 */
component accessors=true displayName="Preside REST Response" {

	property name="data"         type="any";
	property name="mimeType"     type="string"  default="application/json";
	property name="statusCode"   type="numeric" default=200;
	property name="headers"      type="struct";

	/**
	 * Returns all response properties as a simple CFML struct
	 *
	 * @autodoc true
	 */
	public struct function getMemento() {
		return {
			  data         = getData()
			, mimeType     = getMimeType()
			, statusCode   = getStatusCode()
			, headers      = getHeaders()
		};
	}

	/**
	 * Sets the numeric status code of the response and returns
	 * reference to self so that methods can be chained
	 *
	 * @statuscode.hint Numeric status code to set on the response
	 * @autodoc true
	 */
	public any function setStatus( required numeric statusCode ) {
		variables.statusCode = arguments.statusCode;

		return this;
	}

	/**
	 * Sets headers on the rest response object. Can be called multiple
	 * times to build a greater collection of headers
	 *
	 * @headers.hint Structure containing headers where struct keys are header names and values are corresponding header values
	 * @autodoc true
	 */
	public any function setHeaders( required struct headers ) {
		variables.headers = variables.headers ?: {};
		variables.headers.append( arguments.headers )

		return this;
	}

	/**
	 * Sets the data of the response. This data will later be converted into
	 * whichever response format is specified for the request (json by default)
	 *
	 * @data.hint the data to set
	 * @autodoc true
	 *
	 */
	public any function setData( required any data ) {
		variables.data = arguments.data;

		return this;
	}

	/**
	 * Sets the data of the response to NULL which instructs the response processor
	 * to return an empty body
	 *
	 * @autodoc true
	 *
	 */
	public any function noData() {
		variables.data = NullValue();

		return this;
	}

	/**
	 * Sets the mime type of the response and returns
	 * reference to self so that methods can be chained
	 *
	 * @mimetype.hint mime type of the response, e.g. 'application/json'
	 * @autodoc true
	 */
	public any function setMimeType( required string mimeType ) {
		variables.mimeType = arguments.mimeType;

		return this;
	}

}