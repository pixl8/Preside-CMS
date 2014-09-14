/**
 * The link object represents a link to just about anything, be it page in the site tree, an email address or
 * plain link
 */

component extends="preside.system.base.SystemPresideObject" labelfield="internal_title" output=false displayname="Link" {

	property name="internal_title" type="string" dbtype="varchar" maxlength="100" required=true  uniqueindexes="linktitle";
	property name="type"           type="string" dbtype="varchar" maxlength="10"  required=true  format="regex:(external|sitetree|email|asset)";
	property name="title"          type="string" dbtype="varchar" maxlength="200" required=false;
	property name="target"         type="string" dbtype="varchar" maxlength="20"  required=false format="regex:_(blank|self|parent|top)";
	property name="link"           type="string" dbtype="varchar" maxlength="500" required=false;

	property name="page"  relationship="many-to-one" relatedto="page"  required=false;
	property name="asset" relationship="many-to-one" relatedto="asset" required=false;

}