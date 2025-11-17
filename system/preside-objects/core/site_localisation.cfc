/**
 * The Site localisation object allows selection of locale specific settings
 *
 * @feature sites
 */
component labelfield="none" extends="preside.system.base.SystemPresideObject" displayName="Site localisation" {
	property name="short_date_format"  type="string" dbtype="varchar" maxlength="50"  required=false;
	property name="long_date_format"   type="string" dbtype="varchar" maxlength="50"  required=false;
	property name="time_format"        type="string" dbtype="varchar" maxlength="10"  required=false enum="timeFormat";

	property name="site" 	relationship="many-to-one"                     			  required=true;
}