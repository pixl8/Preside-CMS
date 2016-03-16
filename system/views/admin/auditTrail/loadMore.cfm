<cfscript>
    logs    = prc.logs ?: [];
</cfscript>
<cfif val(logs.recordcount)>
    <cfoutput query="logs">
        <cfscript>
            auditTrailData.Action      = logs.Action;
            auditTrailData.Type        = logs.Type;
            auditTrailData.Detail      = DeserializeJSON( logs.Detail );
            auditTrailData.datecreated = logs.datecreated;
            auditTrailData.id          = logs.id;
        </cfscript>
        <div class="message-item">
            <div class="message-inner">
                <div class="message-head clearfix">
                    <div class="avatar pull-left">
                        <img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( known_as )#" />
                    </div>
                    <div class="user-detail">
                         <h5>
                            #known_as#
                        </h5>
                        <div class="post-meta">
                            <span>#datetimeformat(datecreated,"medium")#</span>
                        </div>
                    </div>
                </div>
                <div>
                   #renderLogMessage( log=auditTrailData )#
                </div>
            </div>
        </div>
    </cfoutput>
</cfif>