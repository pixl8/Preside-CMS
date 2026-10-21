<!---@feature admin--->
<cfscript>
	experiments = args.experiments ?: [];
	hasSignpost = ArrayLen( experiments );
</cfscript>

<cfoutput>
	<li<cfif hasSignpost> class="labs-signpost-anchor" data-labs-signpost="true" data-signpost-title="#EncodeForHtmlAttribute( translateResource( 'cms:labs.signpost.title' ) )#" data-dismiss-url="#EncodeForHtmlAttribute( args.dismissUrl )#" data-csrf-token="#EncodeForHtmlAttribute( args.csrfToken )#"</cfif>>
		#args.userMenu#

		<cfif hasSignpost>
			<div id="labs-signpost-content" class="hide">
				<p>#EncodeForHtml( translateResource( "cms:labs.signpost.intro" ) )#</p>
				<ul class="list-unstyled">
					<cfloop array="#experiments#" item="experiment" index="experimentIndex">
						<li><i class="fa fa-fw fa-flask"></i> #EncodeForHtml( experiment.title )#</li>
					</cfloop>
				</ul>
				<div class="labs-signpost-actions">
					<button type="button" class="btn btn-xs btn-text labs-signpost-dismiss">#EncodeForHtml( translateResource( "cms:labs.signpost.dismiss" ) )#</button>
					<a class="btn btn-primary" href="#EncodeForHtmlAttribute( args.labsUrl )#">#EncodeForHtml( translateResource( "cms:labs.signpost.link" ) )#</a>
				</div>
			</div>
		</cfif>
	</li>
</cfoutput>
