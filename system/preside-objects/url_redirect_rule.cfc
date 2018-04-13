/**
 * The URL Redirect rule object is used to store individual URL redirect rules. These rules
 * can use regex, etc. and are used to setup dynamic and editorial redirects.
 *
 * @dataExportFields id,label,source_url_pattern,redirect_type,exact_match_only,redirect_to_link,datecreated,datemodified
 */
component extends="preside.system.base.SystemPresideObject" displayName="URL Redirect rule" {
	property name="label" uniqueindexes="redirectUrlLabel";

	property name="source_url_pattern" type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="sourceurl";
	property name="redirect_type"      type="string"  dbtype="varchar" maxlength=3   required=true enum="redirectType";
	property name="exact_match_only"   type="boolean" dbtype="boolean"               required=false default=false;

	property name="redirect_to_link" relationship="many-to-one" relatedto="link" required=true;
}