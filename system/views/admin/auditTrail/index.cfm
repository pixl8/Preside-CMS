<cfscript>
    logs    = prc.logs ?: [];
    perpage = prc.perpage;
    start   = prc.start;
</cfscript>

<cfif logs.recordcount>
    <div class="container">
        <cfoutput query="logs" startrow="#start#" maxrows="#perpage#">
            <div class="message-item">
                <div class="message-inner">
                    <div class="message-head clearfix">
                        <div class="avatar pull-left">
                            <img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( known_as )#" />
                        </div>
                        <div class="user-detail">
                            <h5>#known_as#</h5>
                            <div class="post-meta">
                                <span>#datetimeformat(datecreated,"medium")#</span>
                            </div>
                        </div>
                    </div>
                    <div>
                        #action#
                    </div>
                </div>
            </div>
        </cfoutput>
    </div>
    <cfoutput>
        <div class="pull-right">
            <cfif start gt 1>
                <cfset link = "#event.buildAdminLink( linkTo='auditTrail', queryString='start=' & start - perpage )#">
                <a href="#link#"><button class="btn btn-primary btn-sm">#translateResource( uri='cms:datatables.previous' )#</button></a>
            <cfelse>
                <button class="btn btn-sm btn-default disabled">#translateResource( uri='cms:datatables.previous' )#</button>
            </cfif>
            <cfif ( start + perpage - 1 ) lt logs.recordcount>
                <cfset link = "#event.buildAdminLink( linkTo='auditTrail', queryString='start=' & start + perpage )#">
                <a href="#link#"><button class="btn btn-primary btn-sm">#translateResource( uri='cms:datatables.next' )#</button></a>
            <cfelse>
                <button class="btn btn-sm btn-default disabled">#translateResource( uri='cms:datatables.next' )#</button>
            </cfif>
        </div>
    </cfoutput>
<cfelse>
    <p><em>There are no audit logs to see here.</em></p>
</cfif>