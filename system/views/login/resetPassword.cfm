<!---@feature websiteUsers and siteTree--->
<cfparam name="args.title"                  field="page.title" editable="true" />
<cfparam name="args.empty_password"         field="reset_password.empty_password"         default="You must supply a new password." />
<cfparam name="args.passwords_do_not_match" field="reset_password.passwords_do_not_match" default="The passwords you supplied do not match." />
<cfparam name="args.unknown_error"          field="reset_password.unknown_error"          default="An unknown error occurred while attempting to reset your password. Please try again." />
<cfparam name="prc.policyMessage" default="" />
<cfparam name="rc.token"          default="" />
<cfparam name="rc.message"        default="" />

<cfoutput>
    <h1>#args.title#</h1>

    <cfswitch expression="#rc.message#">
        <cfcase value="EMPTY_PASSWORD">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.empty_password ) )>
                    #args.empty_password#
                <cfelse>
                    #translateResource( 'cms:resetLogin.empty.password.error' )#
                </cfif>
            </div>
        </cfcase>
        <cfcase value="PASSWORDS_DO_NOT_MATCH">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.passwords_do_not_match ) )>
                    #args.passwords_do_not_match#
                <cfelse>
                    #translateResource( 'cms:resetLogin.passwords.do.not.match.error' )#
                </cfif>
            </div>
        </cfcase>
        <cfcase value="PASSWORD_NOT_STRONG_ENOUGH">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( prc.policyMessage ) )>
                    #prc.policyMessage#
                <cfelse>
                    #translateResource( 'cms:resetLogin.password.not.strong.enough.error' )#
                </cfif>
            </div>
        </cfcase>
        <cfcase value="UNKNOWN_ERROR">
            <div class="alert alert-danger" role="alert">
                <cfif len( trim( args.unknown_error ) )>
                    #args.unknown_error#
                <cfelse>
                    #translateResource( 'cms:resetLogin.unknown.error' )#
                </cfif>
            </div>
        </cfcase>
    </cfswitch>

    <form action="#event.buildLink( linkTo='login.resetPasswordAction' )#" method="post">
        <input type="hidden" name="token" value="#rc.token#" />
        <div class="form-group">
            <label for="passwordField">#translateResource( uri="page-types.reset_password:newPassword.label" )#</label>
            <input type="password" name="password" id="passwordField" class="form-control">
        </div>

        <div class="form-group">
            <label for="passwordConfirmationField">#translateResource( uri="page-types.reset_password:confirmPassword.label" )#</label>
            <input type="password" name="passwordConfirmation" id="passwordConfirmationField" class="form-control">
        </div><br/>

        <div class="form-group">
            <p><a href="#event.buildLink( page="login" )#">#translateResource( uri="page-types.reset_password:returnToLoginLink.title" )#</a></p>
            <button type="submit" class="btn btn-danger">#translateResource( uri="page-types.reset_password:submitButton.title" )#</button>
        </div>
    </form>
</cfoutput>