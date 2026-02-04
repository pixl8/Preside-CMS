/**
 * The URL Redirect rule object is used to store individual URL redirect rules. These rules
 * can use regex, etc. and are used to setup dynamic and editorial redirects.
 *
 * @dataExportFields      id,label,source_url_pattern,redirect_type,exact_match_only,keep_query_string,redirect_to_link,datecreated,datemodified
 * @datamanagerEnabled    true
 * @datamanagerGridFields label,source_url_pattern,redirect_to_link,redirect_type,exact_match_only,datecreated,datemodified
 * @feature               urlRedirects
 */
component extends="preside.system.base.SystemPresideObject" displayName="URL Redirect rule" {
	property name="label" uniqueindexes="redirectUrlLabel";

	property name="source_url_pattern" type="string"  dbtype="varchar" maxlength=200 required=true  uniqueindexes="sourceurl";
	property name="redirect_type"      type="string"  dbtype="varchar" maxlength=3   required=true  default="302" enum="redirectType";
	property name="exact_match_only"   type="boolean" dbtype="boolean"               required=false default=true;
	property name="keep_query_string"  type="boolean" dbtype="boolean"               required=false default=false;

	property name="redirect_to_link" relationship="many-to-one" relatedto="link" required=true;
	property name="rendered_redirect_link" type="string" dbtype="text" formula="${prefix}redirect_to_link" adminRenderer="none" dataExportRenderer="Link" searchSearchable=false autofilter=false;
}