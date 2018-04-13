<cfscript>
	promptMessage = prc.promptMessage ?: "";
	templateId    = rc.template ?: "";
	clearAction   = event.buildAdminLink( "emailcenter.queue.clearAction" );
	cancelAction  = event.buildAdminLink( "emailcenter.queue" );
</cfscript>

<cfoutput>
	<div class="alert alert-warning">
		<p>
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#promptMessage#
		</p>
		<br>

		<form action="#clearAction#" method="post">
			<input type="hidden" name="template" value="#templateId#">

			<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
				<i class="fa fa-reply bigger-110"></i>
				#translateResource( "cms:cancel.btn" )#
			</a>

			<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
				<i class="fa fa-check bigger-110"></i>
				#translateResource( "cms:emailcenter.queue.clear.confirm.btn" )#
			</button>
		</form>
	</div>
</cfoutput>