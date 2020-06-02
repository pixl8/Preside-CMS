<cfparam name="args.action"          type="string" />
<cfparam name="args.type"            type="string" />
<cfparam name="args.email_address"   type="string" />
<cfparam name="args.known_as"        type="string" />
<cfparam name="args.userLink"        type="string" />
<cfparam name="args.actionLink"      type="string" />
<cfparam name="args.uri"             type="string" />
<cfparam name="args.record_id"       type="string" />
<cfparam name="args.user_ip"         type="string" />
<cfparam name="args.user_agent"      type="string" />
<cfparam name="args.actionTitle"     type="string" />
<cfparam name="args.actionIconClass" type="string" />
<cfparam name="args.typeLink"        type="string" />
<cfparam name="args.typeTitle"       type="string" />
<cfparam name="args.typeIconClass"   type="string" />
<cfparam name="args.recordLink"      type="string" default="" />
<cfparam name="args.logDate"         type="date" />
<cfparam name="args.datecreated"     type="date" />

<cfoutput>
	<div class="timeline-item clearfix" data-date="#args.logDate#">
		<div class="timeline-info">
			<img class="user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( args.email_address ) ) )#?r=g&d=mm&s=40" alt="" />
			<span class="label label-info label-sm">#TimeFormat( args.datecreated, "HH:mm" )#</span>
		</div>
		<div class="widget-box transparent">
			<div class="widget-header widget-header-small">
				<h5 class="widget-title smaller">
					<i class="fa fa-fw #args.actionIconClass#"></i>
					<a href="#args.actionLink#" class="blue">#args.actionTitle#</a>
				</h5>
				<span class="widget-toolbar no-border">
					<i class="fa fa-fw bigger-110 fa-clock-o"></i>
					<a href="#args.userLink#">#args.known_as#</a> @
					#renderContent( renderer="datetime", data=args.dateCreated )#
				</span>
			</div>

			<div class="widget-body">
				<div class="widget-main">
					#renderLogMessage( log=args )#
				</div>
			</div>

			<div class="widget-header widget-header-small">
				<span class="widget-title smaller light-grey">
					<cfif Len( Trim( args.record_id ) )>
						<a href="#args.recordLink#" class="light-grey">
							<i class="fa fa-fw fa-filter"></i>
							#translateResource( "cms:audittrail.filter.by.record.id" )#
						</a>
						|
					</cfif>
					<a href="#args.typeLink#" class="light-grey">
						<i class="fa fa-fw #args.typeIconClass#"></i>
						#args.typeTitle#
					</a>
				</span>
				<span class="widget-toolbar no-border light-grey">
					<strong>#translateResource( 'cms:audittrail.item.ip'         )#:</strong> #args.user_ip#
					<strong>#translateResource( 'cms:audittrail.item.user.agent' )#:</strong> #args.user_agent#
				</span>
			</div>
		</div>
	</div>
</cfoutput>