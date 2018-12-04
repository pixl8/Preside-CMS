/**
 * A log of every email sent through the templating system
 *
 * @versioned      false
 * @nodatemodified true
 * @feature        emailLinkShortener
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="label" formula="coalesce( ${prefix}title, ${prefix}body, ${prefix}full_url )";

	property name="link_hash" type="string" dbtype="varchar" maxlength=32 required=true uniqueindexes="linkhash";
	property name="href"      type="string" dbtype="text";
	property name="title"     type="string" dbtype="text";
	property name="body"      type="string" dbtype="text";
}