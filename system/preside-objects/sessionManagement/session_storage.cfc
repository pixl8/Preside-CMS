/**
 * The session storage object stores sessions that have been persisted to the database
 * using Preside's session management system.
 *
 * @versioned      false
 * @useCache       false
 * @noLabel        true
 * @nodatemodified true
 */
component extends="preside.system.base.SystemPresideObject" displayName="Session storage"  {
	property name="expiry" type="numeric" dbtype="int"      required=true indexes="expiry";
	property name="value"  type="string"  dbtype="longtext" required=true;
}