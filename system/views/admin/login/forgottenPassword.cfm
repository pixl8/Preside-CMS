<cfoutput>
	<div class="position-relative">
		<div id="forgot-box" class="forgot-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
					<h4 class="header red lighter bigger">
						<i class="fa fa-key"></i>
						#translateResource( 'cms:forgotpassword.title' )#<!--Retrieve Password-->
					</h4>

					<div class="space-6"></div>
					<p>
						#translateResource( 'cms:forgotpassword.prompt' )#<!--Enter your email and to receive instructions-->
					</p>

					<form action="#event.buildAdminLink( 'login.sendResetInstructions' )#" method="post">
						<fieldset>
							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="text" class="form-control" placeholder="#translateResource( 'cms:forgotpassword.loginIdOrEmail.placeholder' )#" name="loginId" value="#event.getValue( name="loginId", defaultValue="" )#" />
									<i class="fa fa-user"></i>
								</span>
							</label>

							<div class="row-fluid">
								<button class="span10 offset2 btn btn-sm btn-danger">
									<i class="fa fa-envelope-alt"></i>
									#translateResource( 'cms:forgotpassword.button' )#
								</button>

								<a href="#event.buildAdminLink( linkTo='login' )#" class="pull-right">
									#translateResource( 'cms:forgotpassword.login.link' )#
								</a>
							</div>
						</fieldset>
					</form>
				</div><!--/widget-main-->
			</div><!--/widget-body-->
		</div><!--/forgot-box-->


	</div><!--/position-relative-->
</cfoutput>