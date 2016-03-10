<cfscript>
	logs = prc.logs ?: [];
</cfscript>

<cfoutput>
	<cfif logs.recordcount>
        <div class="container">
			<cfloop query="logs" >
                <div class="message-item">
                    <div class="message-inner">
                        <div class="message-head clearfix">
                            <div class="avatar pull-left">
                                <img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( event.getAdminUserDetails().email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( event.getAdminUserDetails().known_as )#" />
                            </div>
                            <div class="user-detail">
                                <h5 >#type#</h5>
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
			</cfloop>
        </div>
	<cfelse>
		<p><em>There are no audit logs to see here.</em></p>
	</cfif>
</cfoutput>