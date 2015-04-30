/**
 * The multilingual language object stores
 * languages that can be available to the Presides core
 * multilingual content system
 *
 * @displayName Multilingual language
 * @labelField  name
 *
 */
component extends="preside.system.base.SystemPresideObject" feature="multilingual" {
	property name="name"          type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="language_name" control="textinput";
	property name="iso_code"      type="string"  dbtype="varchar" maxlength=2   required=true uniqueindexes="iso_code";
	property name="native_name"   type="string"  dbtype="varchar" maxlength=200 required=true control="textinput";
	property name="right_to_left" type="boolean" dbtype="boolean"               required=false default=false;
}