/**
 * A password policy for a given context includes simple rules around password requirements
 *
 * @labelfield  context
 */
component extends="preside.system.base.SystemPresideObject" displayName="Password policy" {

	property name="context"       type="string"  dbtype="varchar" required=true  maxlength="20" uniqueindexes="passwordpolicycontext";

	property name="min_strength"  type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=100;
	property name="min_length"    type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;
	property name="min_uppercase" type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;
	property name="min_numeric"   type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;
	property name="min_symbols"   type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;

	property name="message"       type="string"  dbtype="text"    required=false;

}