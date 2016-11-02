/**
 * Layout, subject and body of a single email, either system, transactional or marketing.
 *
 * @labelfield file_name
 * @versioned  false
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email template attachment"  {
	property name="template" relationship="many-to-one" relatedTo="email_template" required=true uniqueindexes="filename|1";
	property name="file_name"    type="string" dbtype="varchar" maxlength=200      required=true uniqueindexes="filename|2";
	property name="storage_path" type="string" dbtype="varchar" maxlength=200      required=true;
}