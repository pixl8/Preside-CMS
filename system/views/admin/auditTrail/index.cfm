<cfscript>
    logs         = prc.logs                             ?                : [];
    userFilter   = structKeyExists( rc, "user" )        ? rc.user        : "";
    actionFilter = structKeyExists( rc, "action" )      ? rc.action      : "";
    dateFilter   = structKeyExists( rc, "dateFilters" ) ? rc.dateFilters : "";
</cfscript>
<cfoutput>
    <div class="container">
        <div class="col-sm-5 col-md-4 col-lg-4">
            <div class="btn-group pull-right">
                <button data-toggle="dropdown" class="btn btn-success">
                    <span class="fa fa-caret-down"></span>
                    <i class="fa fa-plus"></i>
                    #translateResource( uri='cms:auditTrail.addFilter' )#
                </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
                    <li data-field="DateRange" class="date">
                        <a href="#event.buildAdminLink( linkTo='auditTrail.getFilters', queryString='type=dateCreated&user=#userFilter#&action=#actionFilter#&dateFilters=#dateFilter#' )#" data-toggle="bootbox-modal" data-title="#translateResource( uri='cms:auditTrail.dateRange' )#">
                            <i class="fa fa-calendar"></i>&nbsp;
                            #translateResource( uri='cms:auditTrail.dateRange' )#
                        </a>
                    </li>
                    <li data-field="activity" class="field">
                        <a href="#event.buildAdminLink( linkTo='auditTrail.getFilters', queryString='type=Action&user=#userFilter#&action=#actionFilter#&dateCreated=#dateFilter#' )#" data-toggle="bootbox-modal" data-title="#translateResource( uri='cms:auditTrail.action' )#">
                            <i class="fa fa-cogs"></i>&nbsp;
                            #translateResource( uri='cms:auditTrail.action' )#
                        </a>
                    </li>
                    <li data-field="user" class="field">
                        <a href="#event.buildAdminLink( linkTo='auditTrail.getFilters', queryString='type=User&user=#userFilter#&action=#actionFilter#&dateCreated=#dateFilter#' )#" data-toggle="bootbox-modal" data-title="#translateResource( uri='cms:auditTrail.user' )#">
                            <i class="fa fa-user"></i>&nbsp;
                            #translateResource( uri='cms:auditTrail.user' )#
                        </a>
                    </li>
                </ul>
            </div>
            <div class="clearfix"></div>&nbsp;
            <cfif len(prc.filterLabel)>
                <cfloop array="#prc.filterLabel#" index="filter">
                    <div class="alert alert-info">
                        <div><i class="#filter.icon#"></i>&nbsp;#filter.value#</div>
                    </div>
                </cfloop>
            </cfif>
        </div>
        <div class="col-sm-7 col-md-8 col-lg-8">
            <cfif val(logs.recordcount)>
                <div id="audit-trail">
                    <cfoutput query="logs">
                        <cfscript>
                            auditTrailData.Action      = logs.Action;
                            auditTrailData.Type        = logs.Type;
                            auditTrailData.Detail      = isJson( logs.Detail ) ? DeserializeJSON( logs.Detail ) : logs.Detail;
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
                                            <span>#datetimeformat( datecreated,"medium" )#</span>
                                        </div>
                                    </div>
                                </div>
                                <div>
                                    #renderLogMessage( log=auditTrailData )#
                                </div>
                            </div>
                        </div>
                    </cfoutput>
                </div>
            <cfelse>
                <p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
            </cfif>
            <div class="load-more text-center">
                <a class="load-more btn btn-primary" data-load-more-target="audit-trail" data-href="#event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='user=#userFilter#&action=#actionFilter#&dateFilters=#dateFilter#&page=' )#"><i class="fa fa-plus-circle"></i> #translateResource( uri='cms:auditTrail.loadMore' )#</a>
            </div>
        </div>
    </div>
</cfoutput>