/**
 * The reset password page type object is used to store any fields that are distinct to the system page type 'reset password'
 *
 * @isSystemPageType     true
 * @parentSystemPageType login
 * @pagetypeViewlet      login.resetPassword
 * @feature              websiteUsers
 *
 */
component extends="preside.system.base.SystemPresideObject" displayName="Page type: Reset password" {
    property name="empty_password"         type="string" dbtype="varchar" control="textArea";
    property name="passwords_do_not_match" type="string" dbtype="varchar" control="textArea";
    property name="unknown_error"          type="string" dbtype="varchar" control="textArea";
}