/**
 * @noLabel        true
 * @noId           true
 * @noDateCreated  true
 * @noDateModified true
 * @versioned      false
 * @feature        customObjects
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="custom_object"  relationship="many-to-one" relatedto="custom_object"  required=true ondelete="cascade" uniqueindexes="objectgroup|1" adminRenderer="none";
	property name="security_group" relationship="many-to-one" relatedto="security_group" required=true ondelete="cascade" uniqueindexes="objectgroup|2";
}
