<cfparam name="args.title"                  field="page.title" editable="true" />
<cfparam name="args.empty_password"         field="reset_password.empty_password"         default="You must supply a new password." />
<cfparam name="args.passwords_do_not_match" field="reset_password.passwords_do_not_match" default="The passwords you supplied do not match." />
<cfparam name="args.unknown_error"          field="reset_password.unknown_error"          default="An unknown error occurred while attempting to reset your password. Please try again." />

<cfparam name="rc.token"   default="" />
<cfparam name="rc.message" default="" />

<cfoutput>
    <h1>#args.title#</h1>

    <cfswitch expression="#rc.message#">
        <cfcase value="EMPTY_PASSWORD">
            <div class="alert alert-danger" role="alert">#args.empty_password#</div>
        </cfcase>
        <cfcase value="PASSWORDS_DO_NOT_MATCH">
            <div class="alert alert-danger" role="alert">#args.passwords_do_not_match#</div>
        </cfcase>
        <cfcase value="UNKNOWN_ERROR">
            <div class="alert alert-danger" role="alert">#args.unknown_error#</div>
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