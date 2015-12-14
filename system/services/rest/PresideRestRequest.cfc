/**
 * Object to represent a REST request. Used in REST requests (see [[restframework]]).
 * This is a simple bean with the following properties:
 *
 *     api      (e.g. /myapi/v2)
 *     uri      (e.g. /blogs/2345083745/)
 *     verb     (e.g. POST, GET, etc.)
 *     resource (e.g. the resource that matches the request - a struct with various information about the resource)
 *     finished (e.g. whether or not we're done with the request)
 *
 * @autodoc true
 */
component accessors=true displayName="Preside REST Request" {

	property name="api"      type="string"  default="/";
	property name="uri"      type="string"  default="/";
	property name="verb"     type="string"  default="GET";
	property name="finished" type="boolean" default=false;
	property name="resource" type="struct";

}