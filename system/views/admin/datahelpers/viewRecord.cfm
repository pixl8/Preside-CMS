<cfscript>
	leftCol                  = args.leftCol  ?: "";
	rightCol                 = args.rightCol ?: "";
	preRenderRecord          = args.preRenderRecord          ?: "";
	preRenderRecordLeftCol   = args.preRenderRecordLeftCol   ?: "";
	preRenderRecordRightCol  = args.preRenderRecordRightCol  ?: "";
	postRenderRecordLeftCol  = args.postRenderRecordLeftCol  ?: "";
	postRenderRecordRightCol = args.postRenderRecordRightCol ?: "";
	postRenderRecord         = args.postRenderRecord         ?: "";
</cfscript>

<cfoutput>
	#preRenderRecord#

	<div class="row">
		<div class="col-lg-12">
			#preRenderRecordLeftCol#
			#leftCol#
			#postRenderRecordLeftCol#
		</div>
		<div class="col-lg-12">
			#preRenderRecordRightCol#
			#rightCol#
			#postRenderRecordRightCol#
		</div>
	</div>

	#postRenderRecord#
</cfoutput>
