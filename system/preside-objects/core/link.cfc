/**
 * The link object represents a link to just about anything, be it page in the site tree, an email address or
 * plain link
 *
 * @labelfield                      internal_title
 * @datamanagerEnabled              true
 * @datamanagerGridFields           internal_title,type,datecreated,datemodified
 * @datamanagerDisallowedOperations delete,clone
 */
component extends="preside.system.base.SystemPresideObject" displayname="Link" {

	property name="internal_title"    type="string"  dbtype="varchar" maxlength="100" required=true  uniqueindexes="linktitle";
	property name="type"              type="string"  dbtype="varchar" maxlength="20"  required=false default="external"  enum="linkType";
	property name="title"             type="string"  dbtype="varchar" maxlength="200" required=false;
	property name="page_anchor"       type="string"  dbtype="varchar" maxlength="30"  required=false;
	property name="target"            type="string"  dbtype="varchar" maxlength="20"  required=false enum="linkTarget";
	property name="nofollow"          type="boolean" dbtype="boolean"                 required=false default=false;
	property name="text"              type="string"  dbtype="varchar" maxlength="400" required=false;

	property name="external_protocol" adminviewgroup="external" type="string"  dbtype="varchar" maxlength="10"  required=false default="http://" enum="linkProtocol";
	property name="external_address"  adminviewgroup="external" type="string"  dbtype="varchar" maxlength="255" required=false;
	property name="email_address"     adminviewgroup="email"    type="string"  dbtype="varchar" maxlength="255" required=false;
	property name="email_subject"     adminviewgroup="email"    type="string"  dbtype="varchar" maxlength="100" required=false;
	property name="email_body"        adminviewgroup="email"    type="string"  dbtype="varchar" maxlength="255" required=false;
	property name="email_anti_spam"   adminviewgroup="email"    type="boolean" dbtype="boolean"                 required=false default=true;

	property name="page"  adminviewgroup="page"  relationship="many-to-one" relatedto="page"  required=false;
	property name="asset" adminviewgroup="asset" relationship="many-to-one" relatedto="asset" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="image"                        relationship="many-to-one" relatedto="asset" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" allowedTypes="image";

}