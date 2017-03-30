/**
 * The link object represents a link to just about anything, be it page in the site tree, an email address or
 * plain link
 *
 */
component extends="preside.system.base.SystemPresideObject" labelfield="internal_title" output=false displayname="Link" {

	property name="internal_title"    type="string" dbtype="varchar" maxlength="100" required=true  uniqueindexes="linktitle";
	property name="type"              type="string" dbtype="varchar" maxlength="20"  required=false default="external"  enum="linkType";
	property name="title"             type="string" dbtype="varchar" maxlength="200" required=false;
	property name="target"            type="string" dbtype="varchar" maxlength="20"  required=false enum="linkTarget";
	property name="text"              type="string" dbtype="varchar" maxlength="400" required=false;

	property name="external_protocol" type="string"  dbtype="varchar" maxlength="10"  required=false default="http://" enum="linkProtocol";
	property name="external_address"  type="string"  dbtype="varchar" maxlength="255" required=false;
	property name="email_address"     type="string"  dbtype="varchar" maxlength="255" required=false;
	property name="email_subject"     type="string"  dbtype="varchar" maxlength="100" required=false;
	property name="email_body"        type="string"  dbtype="varchar" maxlength="255" required=false;
	property name="email_anti_spam"   type="boolean" dbtype="boolean"                 required=false default=true;

	property name="page"  relationship="many-to-one" relatedto="page"  required=false;
	property name="asset" relationship="many-to-one" relatedto="asset" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="image" relationship="many-to-one" relatedto="asset" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" allowedTypes="image";

}