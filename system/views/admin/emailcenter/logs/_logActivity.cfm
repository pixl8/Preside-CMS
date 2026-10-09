<!---@feature admin and emailCenter--->
<cfparam name="args.logDate"                    />
<cfparam name="args.emailAddress"    default="" />
<cfparam name="args.datecreated"     default="" />
<cfparam name="args.actionIconClass" default="" />
<cfparam name="args.actionTitle"     default="" />
<cfparam name="args.message"         default="" />
<cfparam name="args.ipAddress"       default="" />
<cfparam name="args.userAgent"       default="" />
<cfparam name="args.showAuditTrail"  default=true />
<cfparam name="args.classification"  default="" />
<cfparam name="args.botScore"        default="" />
<cfparam name="args.botSignals"      default="" />

<cfscript>
	classification       = LCase( Trim( args.classification ) );
	knownClassifications = [ "human", "bot", "tentative" ];
	classificationLabel  = "";

	if ( ArrayFind( knownClassifications, classification ) ) {
		classificationLabel = translateResource( "cms:mailcenter.logs.action.classification.#classification#" );
	}

	signalsLabel = Len( Trim( args.botSignals ) ) ? HtmlEditFormat( args.botSignals ) : translateResource( "cms:mailcenter.logs.action.signals.none" );
</cfscript>

<cfoutput>
	<div class="timeline-item clearfix" data-date="#args.logDate#">
		<div class="timeline-info">
			<img class="user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( args.emailAddress ) ) )#?r=g&d=mm&s=40" alt="" />
			<span class="label label-info label-sm">#TimeFormat( args.datecreated, "HH:mm" )#</span>
		</div>
		<div class="widget-box transparent">
			<div class="widget-header widget-header-small">
				<h5 class="widget-title smaller">
					<i class="fa fa-fw #args.actionIconClass#"></i>
					#args.actionTitle#
				</h5>
				<span class="widget-toolbar no-border">
					<i class="fa fa-fw bigger-110 fa-clock-o"></i>
					#renderContent( renderer="datetime", data=args.dateCreated )#
				</span>
			</div>

			<div class="widget-body">
				<div class="widget-main">
					#args.message#
					<cfif Len( classificationLabel )>
						<div class="light-grey">
							<strong>#translateResource( 'cms:mailcenter.logs.action.classification.label' )#:</strong> #classificationLabel#
							<cfif IsNumeric( args.botScore )>
								<strong>#translateResource( 'cms:mailcenter.logs.action.score.label' )#:</strong> #NumberFormat( args.botScore, "0" )#
							</cfif>
							<strong>#translateResource( 'cms:mailcenter.logs.action.signals.label' )#:</strong> #signalsLabel#
						</div>
					</cfif>
				</div>
			</div>

			<cfif Len( Trim( args.ipAddress & args.userAgent ) ) && args.showAuditTrail>
				<div class="widget-header widget-header-small">
					<span class="widget-toolbar no-border light-grey">
						<cfif Len( Trim( args.ipAddress ) )>
							<strong>#translateResource( 'cms:audittrail.item.ip' )#:</strong> #args.ipAddress#
						</cfif>
						<cfif Len( Trim( args.userAgent ) )>
							<strong>#translateResource( 'cms:audittrail.item.user.agent' )#:</strong> #args.userAgent#
						</cfif>
					</span>
				</div>
			</cfif>
		</div>
	</div>
</cfoutput>