<cfparam name="args.email_address" type="string" />
<cfparam name="args.known_as"      type="string" />
<cfparam name="args.userLink"      type="string" />
<cfparam name="args.logDate"       type="date" />
<cfparam name="args.datecreated"   type="date" />

<cfoutput>
	<div class="timeline-item clearfix" data-date="#args.logDate#">
		<div class="timeline-info">
			<img class="user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( args.email_address ) ) )#?r=g&d=mm&s=40" alt="" />
			<span class="label label-info label-sm">#TimeFormat( args.datecreated, "HH:mm" )#</span>
		</div>
		<div class="widget-box transparent">
			<div class="widget-header widget-header-small">
				<h5 class="widget-title smaller">
					<a href="#args.userLink#" class="blue">#args.known_as#</a>
				</h5>
				<span class="widget-toolbar no-border">
					<i class="fa fa-fw bigger-110 fa-clock-o"></i>
					#TimeFormat( args.datecreated, "HH:mm" )#
				</span>
			</div>

			<div class="widget-body">
				<div class="widget-main">
					#renderLogMessage( log=args )#
				</div>
			</div>
		</div>
	</div>
</cfoutput>