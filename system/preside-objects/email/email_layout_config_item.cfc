/**
 * Represents a saved configuration item for an email layout (see [[emailtemplatingv1]])
 *
 * @nolabel   true
 * @versioned false
 * @feature   emailCenter
 *
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email layout configuration item"  {
	property name="layout"          type="string" dbtype="varchar"  maxlength=200          required=true  uniqueindexes="layoutconfigitem|1" indexes="layout,layouttemplate|1,layoutblueprint|1,layoutcustom|3"                                             cloneable=true;
	property name="email_template"  relationship="many-to-one" relatedto="email_template"  required=false uniqueindexes="layoutconfigitem|2" indexes="template,layouttemplate|2"  ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" cloneable=true;
	property name="email_blueprint" relationship="many-to-one" relatedto="email_blueprint" required=false uniqueindexes="layoutconfigitem|3" indexes="template,layoutblueprint|2" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" cloneable=true;
	property name="custom_layout"   type="string" dbtype="varchar"  maxlength=200          required=false uniqueindexes="layoutconfigitem|5" indexes="custom,layoutcustom|2"                                                                                cloneable=true;
	property name="item"            type="string" dbtype="varchar"  maxlength=200          required=true  uniqueindexes="layoutconfigitem|4"                                                                                                                cloneable=true;
	property name="value"           type="string" dbtype="longtext"                        required=false                                                                                                                                                   cloneable=true;
}