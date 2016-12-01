/**
 * Represents a saved configuration item for an email layout (see [[emailtemplatingv1]])
 *
 * @nolabel   true
 * @versioned false
 *
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email layout configuration item"  {
	property name="layout"         type="string" dbtype="varchar"  maxlength=200 required=true  uniqueindexes="layoutconfigitem|1" indexes="layout,layouttemplate|1";
	property name="email_template" type="string" dbtype="varchar"  maxlength=200 required=false uniqueindexes="layoutconfigitem|2" indexes="template,layouttemplate|2";
	property name="item"           type="string" dbtype="varchar"  maxlength=200 required=true  uniqueindexes="layoutconfigitem|3";
	property name="value"          type="string" dbtype="longtext"               required=false;
}