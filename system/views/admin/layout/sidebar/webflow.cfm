<!---@feature webflow--->
<cfscript>
  if ( hasCmsPermission( "webflows.navigate" ) ) {
    Echo( renderView(
          view = "/admin/layout/sidebar/_menuItem"
        , args = {
              active  = Len( Trim( prc.objectName ?: "" ) ) && ReFindNoCase( "^webflow_configuration", prc.objectName )
            , link    = event.buildAdminLink( objectName="webflow_configuration" )
            , gotoKey = ""
            , icon    = "fa-code-fork"
            , title   = translateResource( 'preside-objects.webflow_configuration:admin.nav.link' )
          }
    ) );
}
</cfscript>