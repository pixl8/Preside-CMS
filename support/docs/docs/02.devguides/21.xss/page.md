---
id: xss
title: XSS Protection
---

>>> This feature was first introduced in **PresideCMS v10.3.6**. The details below do not apply for older versions of the software.

PresideCMS comes with XSS protection out of the box using the AntiSamy project. This protection will automatically strip unwanted HTML from user input in order to prevent the possibility of successful cross site scripting attacks.

## Configuring protection

The protection is turned on by default but bypassed by default when the logged in user is a CMS administrator. These settings, and also the AntiSamy profile to be used, can be edited in your sites `Config.cfc` file:

```luceescript

public void function configure() {
    super.configure();

    // turn off antisamy (don't do this!)
    settings.antiSamy.enabled = false;     

    // use the "tinymce" AntiSamy policy (default is myspace)
    settings.antiSamy.policy  = "tinymce"; 

    // do not bypass antisamy, even when logged in user is admin
    settings.antiSamy.bypassForAdministrators = false;

    // ...
}
```

The list of possible policies to use are:

* antisamy
* ebay
* myspace
* slashdot
* tinymce

We plan to provide the ability for custom antisamy profiles to be used, but as of v10.3.6, these are the only options available.

For more information on the AntiSamy project, visit [https://www.owasp.org/index.php/Category:OWASP_AntiSamy_Project](https://www.owasp.org/index.php/Category:OWASP_AntiSamy_Project).