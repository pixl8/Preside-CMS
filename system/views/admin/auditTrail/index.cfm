<cfscript>
    logs    = prc.logs ?: [];
</cfscript>
<cfoutput>
    <div class="container">
        <cfif val(logs.recordcount)>
            <div id="audit-trail">
                <cfoutput query="logs">
                    <div class="message-item">
                        <div class="message-inner">
                            <div class="message-head clearfix">
                                <div class="avatar pull-left">
                                    <img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( known_as )#" />
                                </div>
                                <div class="user-detail">
                                    <h5>
                                        <a href="#event.buildAdminLink( linkTo='auditTrail.viewAuditTrail', queryString='id=#logs.id#')#" data-toggle="bootbox-modal" data-title="#translateResource( uri='cms:auditTrail.viewAuditTrail' )#" data-modal-class="full-screen-dialog limited-size">#known_as#</a>
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
            </div>
        <cfelse>
            <p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
        </cfif>
        <div class="load-more text-center">
            <a class="load-more btn btn-primary" data-load-more-target="audit-trail" data-href="#event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='start=' )#"><i class="fa fa-plus-circle"></i> #translateResource( uri='cms:auditTrail.loadMore' )#</a>
        </div>
    </div>
</cfoutput>