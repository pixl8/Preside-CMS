<cfscript>
    logs    = prc.logs ?: [];
</cfscript>
<cfif val(logs.recordcount)>
    <cfoutput query="logs">
        <div class="message-item">
            <div class="message-inner">
                <div class="message-head clearfix">
                    <div class="avatar pull-left">
                        <img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( known_as )#" />
                    </div>
                    <div class="user-detail">
                         <h5>
                            <a href="#event.buildAdminLink( linkTo='auditTrail.viewAuditTrail', queryString='id=#logs.id#')#" data-toggle="bootbox-modal" data-title="View Audit Trail Details" data-modal-class="full-screen-dialog limited-size">#known_as#</a>
                        </h5>
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
</cfif>