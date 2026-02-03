<!---@feature admin and emailCenter--->
<cfscript>
	queued    = NumberFormat( Val( args.stats.queued    ?: "" ) );
	sent      = NumberFormat( Val( args.stats.sent      ?: "" ) );
	delivered = NumberFormat( Val( args.stats.delivered ?: "" ) );
	opened    = NumberFormat( Val( args.stats.opened    ?: "" ) );
	clicks    = NumberFormat( Val( args.stats.clicks    ?: "" ) );
	failed    = NumberFormat( Val( args.stats.failed    ?: "" ) );

	event.include( "/css/admin/specific/emailcenter/stats/" );
</cfscript>
<cfoutput>
	<dl class="list-unstyled email-stats-list">
		<dt>#translateResource( "cms:emailcenter.stats.overview.title" )#</dt>
		<dd>
			<i class="fa fa-hourglass-start orange"></i>&nbsp;
			<span class="fa-lg orange">#queued#</span>
			<span class="grey">#translateResource( uri="cms:emailcenter.stats.queued" )#</span>
		</dd>
		<dd>
			<i class="fa fa-paper-plane blue"></i>&nbsp;
			<span class="fa-lg blue">#sent#</span>
			<span class="grey">#translateResource( uri="cms:emailcenter.stats.sent" )#</span>
		</dd>
		<cfif isFeatureEnabled( "emailDeliveryStats" )>
			<dd>
				<i class="fa fa-check green"></i>&nbsp;
				<span class="fa-lg green">#delivered#</span>
				<span class="grey">#translateResource( uri="cms:emailcenter.stats.delivered" )#</span>
			</dd>
		</cfif>
		<dd>
			<i class="fa fa-envelope green"></i>&nbsp;
			<span class="fa-lg green">#opened#</span>
			<span class="grey">#translateResource( uri="cms:emailcenter.stats.opened" )#</span>
		</dd>
		<dd>
			<i class="fa fa-pointer green"></i>&nbsp;
			<span class="fa-lg green">#clicks#</span>
			<span class="grey">#translateResource( uri="cms:emailcenter.stats.clicks" )#</span>
		</dd>
		<dd>
			<i class="fa fa-exclamation red"></i>&nbsp;
			<span class="fa-lg red">#failed#</span>
			<span class="grey">#translateResource( uri="cms:emailcenter.stats.failed" )#</span>
		</dd>
	</dl>
	<div class="clearfix"></div>
</cfoutput>