<cfparam name="args.title"           field="page.title" editable="true" />
<cfparam name="args.login_required"  field="login.login_required" default="The resource you are attempting to access requires a secure login. Please login using the form below." />
<cfparam name="args.login_failed"    field="login.login_failed"   default="The email address and password combination you supplied did not match our records. Please try again." />

<cfparam name="args.loginId"         field="false" default="" />
<cfparam name="args.password"        field="false" default="" />
<cfparam name="args.message"         field="false" default="" />
<cfparam name="args.rememberMe"      field="false" default="" />
<cfparam name="args.postLoginUrl"    field="false" default="" />
<cfparam name="args.allowRememberMe" field="false" default="#getSystemSetting( "website_users", "allow_remember_me", true )#" />

<cfoutput>
    <h2>#args.title#</h2>

    <cfswitch expression="#args.message#">
        <cfcase value="LOGIN_REQUIRED">
            <div class="alert alert-warning">#args.login_required#</div>
        </cfcase>
        <cfcase value="LOGIN_FAILED">
            <div class="alert alert-warning">#args.login_failed#</div>
        </cfcase>
    </cfswitch>

    <form action="#event.buildLink( linkTo="login.attemptLogin" )#" method="post">
        <input type="hidden" name="postLoginUrl" value="#args.postLoginUrl#">

        <div class="form-group">
            <label for="loginId">#translateResource( uri="page-types.login:emailaddress.label" )#</label>
            <input type="email" id="loginId" name="loginId" value="#args.loginId#" class="form-control">
        </div>
                                    
        <div class="form-group">
            <label for="password">#translateResource( uri="page-types.login:password.label" )#</label>
            <input type="password" id="password" name="password" class="form-control">
        </div>

        <cfif args.allowRememberMe>
            <div class="checkbox">
                <label>
                    <input type="checkbox" name="rememberMe" value="1"<cfif IsBoolean( args.rememberMe ) and args.rememberMe> checked="checked"</cfif>> #translateResource( uri="page-types.login:rememberMe.label" )#
                </label>
            </div>
        </cfif>

        <div class="form-group">
            <p><a href="#event.buildLink( page="forgotten_password" )#">#translateResource( uri="page-types.login:forgottenPasswordLink.title" )#</a></p>
            
            <button type="submit" class="btn btn-default">#translateResource( uri="page-types.login:loginButton.title" )#</button>
        </div>
    </form>
</cfoutput>