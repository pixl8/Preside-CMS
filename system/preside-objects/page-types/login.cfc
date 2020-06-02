/**
 * The login page type object is used to store any fields that are distinct to the system page type 'login'
 *
 * @isSystemPageType true
 * @pagetypeViewlet  login.loginPage
 * @feature          websiteUsers
 *
 */

component extends="preside.system.base.SystemPresideObject" displayName="Page type: Login" {
    property name="login_required" type="string" dbtype="varchar" control="textArea";
    property name="login_failed"   type="string" dbtype="varchar" control="textArea";
}