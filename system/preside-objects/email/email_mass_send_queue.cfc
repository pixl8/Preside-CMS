/**
 * Object for storing a queue of emails to prepare and send
 *
 * @nolabel   true
 * @versioned false
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="id" type="numeric" dbtype="bigint" generator="increment";

	property name="recipient" type="string" dbtype="varchar" maxlength=100 indexes="recipient" required=true uniqueindexes="queuedemail|1";
	property name="template"  relationship="many-to-one" relatedto="email_template"            required=true uniqueindexes="queuedemail|2";

    property name="parameters"      type="string" dbtype="text";
    property name="parameters_hash" type="string" dbtype="varchar" maxlength=32 generator="hash" generate="always" generateFrom="parameters" uniqueIndexes="queuedemail|3";
}