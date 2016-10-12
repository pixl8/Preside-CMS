/**
 * The multilingual language object stores
 * languages that can be available to the Presides core
 * multilingual content system
 *
 * @labelField name
 * @feature    multilingual
 */
component extends="preside.system.base.SystemPresideObject"  displayName="Multilingual language" {
	property name="name"          type="string"  dbtype="varchar" maxlength=200 required=true  uniqueindexes="language_name" control="textinput";
	property name="iso_code"      type="string"  dbtype="varchar" maxlength=5   required=true  uniqueindexes="iso_code" format="languageCode";
	property name="slug"          type="string"  dbtype="varchar" maxlength=5   required=false uniqueindexes="slug"     format="slug";
	property name="native_name"   type="string"  dbtype="varchar" maxlength=200 required=true control="textinput";
	property name="right_to_left" type="boolean" dbtype="boolean"               required=false default=false;
}