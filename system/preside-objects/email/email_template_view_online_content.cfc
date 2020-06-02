/**
 * Stores sent email content for use with 'view online' functionality.
 * We also store a content hash to avoid duplicate records.
 *
 * @nolabel   true
 * @versioned false
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="content_hash" type="string" dbtype="varchar" maxlength=32 required=true uniqueindexes="sentcontent";
	property name="content"      type="string" dbtype="longtext"             required=true;
}