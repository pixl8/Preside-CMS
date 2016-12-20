<cfparam name="args.viewlink">
<cfparam name="args.viewlogtitle">
<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.viewLink#" data-toggle="bootbox-modal" data-title="#HtmlEditFormat( args.viewlogtitle )#" data-modal-class="full-screen-dialog limited-size">
			<i class="fa fa-eye"></i>
		</a>
	</div>
</cfoutput>