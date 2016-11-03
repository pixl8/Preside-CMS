/**
 * Layout, subject and body of a single email, either system, transactional or marketing.
 *
 * @labelfield name
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email template"  {
	property name="name"           type="string" dbtype="varchar" maxlength=200 required=true uniqueindexes="templatename";
	property name="layout"         type="string" dbtype="varchar" maxlength=200 required=true;
	property name="recipient_type" type="string" dbtype="varchar" maxlength=200 required=true;
	property name="subject"        type="string" dbtype="varchar" maxlength=255 required=true;
	property name="from_address"   type="string" dbtype="varchar" maxlength=255 required=true;

	property name="html_body" type="string" dbtype="longtext";
	property name="text_body" type="string" dbtype="longtext";

	property name="attachments" relationship="one-to-many" relatedto="email_template_attachment" relationshipKey="template";
}