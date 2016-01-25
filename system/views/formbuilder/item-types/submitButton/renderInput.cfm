<cfparam name="args.label" type="string" />
<cfparam name="args.name"  type="string" />

<cfoutput>
	<div class="form-group">
		<div class="col-md-offset-2">
			<div class="col-md-9">
				<button name="#args.name#" class="btn" tabindex="#getNextTabIndex()#">#args.label#</button>
			</div>
		</div>
	</div>
</cfoutput>