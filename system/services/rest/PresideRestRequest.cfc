/**
 * Object to represent a REST request. Used in REST requests (see [[restframework]]).
 *
 * @autodoc true
 */
component accessors=true displayName="Preside REST Request" {

	property name="api"      type="string"  default="/";
	property name="uri"      type="string"  default="/";
	property name="verb"     type="string"  default="GET";
	property name="finished" type="boolean" default=false;
	property name="resource" type="struct";
	property name="user"     type="string" default="";

	/**
	 * Returns the API matched by this REST
	 * request. e.g. "/myapi/v2"
	 *
	 * @autodoc true
	 *
	 */
	public string function getApi() {
		return variables.api;
	}

	/**
	 * Returns the resource URI of this REST
	 * request (without the API path)
	 *
	 * @autodoc true
	 *
	 */
	public string function getUri() {
		return variables.uri;
	}

	/**
	 * Returns the HTTP Method (verb) used in this
	 * REST request
	 *
	 * @autodoc true
	 *
	 */
	public string function getVerb() {
		return variables.verb;
	}

	/**
	 * Returns whether or not the REST request
	 * processing is finished
	 *
	 * @autodoc true
	 *
	 */
	public boolean function isFinished() {
		return variables.finished;
	}

	/**
	 * Mark the REST request as finished, indicating
	 * that no further processing of the request
	 * should occur (other than rendering the response)
	 *
	 * @autodoc true
	 */
	public any function finish() {
		setFinished( true );
	}

	/**
	 * Returns the matched resource details
	 * for the REST request.
	 *
	 * @autodoc true
	 *
	 */
	public struct function getResource() {
		return variables.resource ?: {};
	}

}