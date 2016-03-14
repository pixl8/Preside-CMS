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
        <cfelse>
            <p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
        </cfif>
        <div class="load-more">
            <a class="load-more btn btn-primary pull-right" data-load-more-target="audit-trail" href="#event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='start=' )#">#translateResource( uri='cms:auditTrail.loadMore' )#</a>
        </div>
    </div>
</cfoutput>