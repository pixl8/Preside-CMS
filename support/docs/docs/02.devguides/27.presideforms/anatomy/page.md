---
id: presideforms-anatomy
title: Anatomy of a Preside form definition file
---

## Anatomy of a Preside form definition file

### Form element

All forms must have a root `form` element that contains one or more `tab` elements. 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.sentry:" tabsPlacement="left">
    ...
</form>
```

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

A tab element must contain one or more `fieldset` elements.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.sentry:" tabsPlacement="left">
    <tab id="auth" sortorder="10">
        ...
    </tab>
    <tab id="advanced" sortorder="20">
        ...
    </tab>
</form>
```

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
                <td>A value to determine the order in which the tab will be displayed. The lower the number, the earlier the tab will be displayed.</td>
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

### Fieldset elements

A fieldset element can be used to group associated form elements together and for providing some visual indication of that grouping.

A fieldset must contain one or more `field` elements.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.sentry:" tabsPlacement="left">
    <tab id="auth" sortorder="10">
        <fieldset id="authbasic" sortorder="10">
            ...
        </fieldset>
        <fieldset id="authadvanced" sortorder="10">
            ...
        </fieldset>
    </tab>
    ...
</form>
```

#### Attributes

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>id</th>
                <td>A unique identifier value for the fieldset, e.g. "main"</td>
            </tr>
            <tr>
                <th>title</th>
                <td>A value or i18n resource URI that will be used for the fieldset title text</td>
            </tr>
            <tr>
                <th>decription</th>
                <td>A value or i18n resource URI that will be used for the fieldsets description that will be displayed before any form fields in the fieldset</td>
            </tr>
            <tr>
                <th>sortorder</th>
                <td>A value to determine the order in which the fieldset will be displayed within the parent tab. The lower the number, the earlier the fieldset will be displayed.</td>
            </tr>
        </tbody>
    </table>
</div>

### Field elements

`Field` elements define an input field for your form. The attributes required for the field will vary depending on the form control defined (see [[presideforms-controls]]).

A `field` element can have zero or more `rule` child elements for defining customized validation rules.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.sentry:" tabsPlacement="left">
    <tab id="auth" sortorder="10">
        <fieldset id="authbasic" sortorder="10">
            <field name="api_token" control="password" maxLength="50" />
            <field name="repeat_api_token" control="password">
                <rule validator="sameAs">
                    <param name="field" value="api_token" message="system-config.sentry:api_token.match.validation.message" />
                </rule>
            </field>
            <field binding="sentry.configuration_option" />
        </fieldset>
        ...
    </tab>
    ...
</form>
```

#### Attributes

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>name</th>
                <td>Unique name of the form field. Required if binding is not used. </td>
            </tr>
            <tr>
                <th>binding</th>
                <td>Defines a preside object property from which to derive the field definition. Required if name is not used. See [[presideforms-presideobjects]] for further details.</td>
            </tr>
            <tr>
                <th>label</th>
                <td>A label for the field</td>
            </tr>
            <tr>
                <th>placeholder</th>
                <td>Placeholder text for the field. Relevant for form controls that use a placeholder (text inputs and textareas)</td>
            </tr>
            <tr>
                <th>help</th>
                <td>Help text to be displayed in help tooltip for the field</td>
            </tr>
            <tr>
                <th>sortorder</th>
                <td>A value to determine the order in which the field will be displayed within the parent fieldset. The lower the number, the earlier the field will be displayed.</td>
            </tr>
        </tbody>
    </table>
</div>