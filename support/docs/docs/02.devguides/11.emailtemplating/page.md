---
id: emailtemplatingv2
title: Email templating
---

## Overview

As of 10.8.0, Preside comes with a sophisticated but simple system for email templating that allows developers and content editors to work together to create a highly tailored system of delivering both marketing and transactional email.

>>> See [[emailtemplating]] for documentation on the basic email templating system prior to 10.8.0

## Concepts

### Email layouts

Email "layouts" are provided by developers and designers to provide content administrators with a basic set of styles and layout for their emails. Each template can be given configuration options that allow content administrators to tweak the behaviour of the template globally and per email.

An example layout might include a basic header and footer with configurable social media links and company contact details.

### Email blueprint

An email _blueprint_ defines the input parameters that an email that uses the blueprint will receive. For example, a *reset password* blueprint, will receive a `{{resetEmailLink}}` parameter (among others).

System transactional email templates will have a pre-set blueprint, while other blueprints might be available for editorially created emails templates.

### Email template

An email _template_ is the main body of any email and is editorially driven, though developers may provide default content. When creating or configuring an email template, users may choose a layout and possibly choose a blueprint (depending on the type of email and blueprints available).

Any variables defined by the blueprint are available for editors to easily insert into their content and required variables are validated when saving the template.

### System vs Editorial email templates

The development team may provide system transactional email templates such as "reset password" or "Event booking confirmation". These templates are known as *system* templates and are available through the UI for content editors to _edit_. They cannot be created or deleted.

Editorial emails are entirely created by the editorial team and can be used for custom marketing mail outs, etc.



