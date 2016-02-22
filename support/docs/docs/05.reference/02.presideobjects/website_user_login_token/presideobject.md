---
id: "presideobject-website_user_login_token"
title: "Website user login token"
---

## Overview


The website user login token object represents a "remember me" authentication token. This system is being implemented as advocated here: [http://jaspan.com/improved_persistent_login_cookie_best_practice](http://jaspan.com/improved_persistent_login_cookie_best_practice)

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  website_user_login_token</td></tr><tr><th>Table name</th><td>  psys_website_user_login_token</td></tr><tr><th>Path</th><td>  /preside-objects/websiteUserManagement/website_user_login_token.cfc</td></tr></table></div>

## Properties


```luceescript
property name="user"   relationship="many-to-one" relatedTo="website_user"          uniqueindexes="userSeries|1";
property name="series" type="string" dbtype="varchar" maxLength="35" required=true  uniqueindexes="userSeries|2";
property name="token"  type="string" dbtype="varchar" maxLength="60" required=true;
```