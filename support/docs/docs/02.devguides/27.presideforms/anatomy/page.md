---
id: presideforms-anatomy
title: Anatomy of a Preside form definition file
---

## Anatomy of a Preside form definition file

### Form element

All forms must have a root `form` element that contains one or more `tab` elements. 

#### Attributes

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>i18nBaseUri (optional)</th>
                <td>Base i18n resource URI to be used when calculating field labels, tab titles, etc. using convention. For example, "my.form:" would lead to URIs such as "my.form:tab.basic.title", etc.</td>
            </tr>
            <tr>
                <th>tabsPlacement (optional)</th>
                <td>Placement of the tabs UI in the admin. Valid values are: left, right, below and top (default)</td>
            </tr>
        </tbody>
    </table>
</div> 


### Tab element

The tab element defines a tab pane. In the admin interface, tabs will appear using a twitter bootstrap tabs UI; how tabs appear in your application's front end is up to you. All forms must have at least one tab element; a form with only a single tab will be displayed without any tabs UI.

#### Attributes

All attributes below are optional, although `id` is strongly advised. `title` and `description` attributes can be left out and defined using convention in i18n `.properties` file (see the `i18nBaseUri` form attribute above).

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>id</td>
                <td>A unique identifier value for the tab, e.g. "standard"</td>
            </tr>
            <tr>
                <th>sortorder</td>
                <td>A value to determine the order in which the tab will be displayed</td>
            </tr>
            <tr>
                <th>title</td>
                <td>A value that will be used for the tab title text.</td>
            </tr>
            <tr>
                <th>iconClass</td>
                <td>Class to use to render an icon for the tab, e.g. "fa-calendar" (we use Font Awesome for icons)</td>
            </tr>
            <tr>
                <th>decription</td>
                <td>A value that will be used for the tab and generally output within the tab content section</td>
            </tr>
        </tbody>
    </table>
</div>



### Fieldsets
Fieldsets can be used to group associated form elements together and for styling these elements e.g. two column layout or multiple elements on a sinlge row.

```xml
<form>
	<tab id="addresses" title="system-config.email:addresses.tab.title">
		<fieldset id="addresses">
		    ...
		</fieldset>
	</tab>
</form>
```

#### Available attributes
<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Attribute</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>id</td><td>A unique identifier value for the fieldset, e.g. "main"</td></tr>
            <tr><td>title</td><td>A value that will be used for the fieldset title text</td></tr>
            <tr><td>decription</td><td>A value that will be used for the fieldset and generally output within the fieldset content section</td></tr>
            <tr><td>sortorder</td><td>A value to determine the order in which the fieldset will be output</td></tr>
            <tr><td>deleted</td><td>A boolean value to determine whether or not to display the fieldset based on the id value</td></tr>
        </tbody>
    </table>
</div>

You can also specify a custom layouts for your fieldsets, see below for detail on using layouts.

### Fields

```xml
<form>
	<tab id="addresses" title="system-config.email:addresses.tab.title">
        <field  name="groups_from_address"
                sortorder="10"
                control="textinput"
                required="false"
                label="system-config.email:groups_from_address.label"
                help="system-config.email:groups_from_address.help"
                placeholder="system-config.email:groups_from_address.placeholder"
        />

        <field  name="allow_users_access"
                sortorder="10"
                control="objectPicker"
                object="website_user"
                multiple="true"
                required="false"
                label="preside-objects.asset:field.allow_users_access.title"
                help="preside-objects.asset:field.allow_users_access.help"
        />

        <field sortorder="20" binding="page.slug" control="autoslug" required="true" basedOn="title" />

        <field sortorder="10" binding="page.parent_page" control="sitetreePagePicker" required="true" />

        <field binding="password_policy.min_strength" control="passwordStrengthPicker" />
    </tab>
</form>
```

