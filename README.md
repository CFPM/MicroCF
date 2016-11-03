#MicroCF

Micro CF is a Coldfusion Micro Framework.  It essentially provides the C in MVC and acts as a controller for handling requests to your application.  On top of being able to create pretty URLs, MicroCF provides a middleware type Framework for easily and cleanly adding pre and post interceptors to the application layer.

##Installation

MicroCF is installed using CFPM or can be downloaded from source

###CFPM

    cfpm add micro

##Usage

In application.cfc:

    application.require = new cfpm();

Elsewhere:

    var micro = application.require('micro');
    micro.addRoute('GET', '/', 'controllers.Index.home');
    micro.run();

###Routes

Routes are adding using the addRoute method of MicroCF.  addRoute requires three parameters: HTTP Method, URL Route, Component.Method.  __As a general rule, I suggest keeping your controllers in a single folder at the root directory called controllers.  You can add any hierarchical folder structure inside the controller folder to keep things organized.__

Routes themselves can be dynamic.  This is what make MicroCF so powerful.  Using a simple notation, I can easily define multiple routes.  On top of that, the parameters of the routes are passed into the controller method along with a Request Collection.  Example:

    micro.addRoute('GET', '/{pageName}', 'controllers.Index.page');

This will execute the method 'page' in the Index component and pass along the parameter pageName in a method.  The Index component could look like this:

    component {
        function page(requestCollection, params){
            writeOutput('This page requested is: ' & params.pageName);
        }
    }

Not only can you create dynamic URLs this way, you can also use dynamic methods and classes where the URL route defines the method and/or controller:

    micro.addRoute('GET', '/{pageName}', 'controllers.Index.{pageName}');

This would execute the relevant method in the Index controller.  So hitting /test would execute the Index.test() method.  **If you are using dynamic methods, ensure that you either have a proper 404 method defined, or an onMissingMethod in your component**

We can also add dynamic controllers info MicroCF:

    micro.addRoute('GET', '/{controller}/{method}', 'controllers.{controller}.{method}');

This allows us to hit an URL like /user/edit which would hit the controllers.user component and execute the edit method

###Middleware

Middleware allows you to execute code before and after your application has run.  This allows you to build tools such as authentication, cross-site request protection, permissions, or something else.  Middleware can be applied to the request as a whole or to individual routes for more specific applications. It should be noted that middleware applied to the micro component only get's applied to routes that come after the middleware.  This gives you some flexibility in covering a majority of your site, but not everything. (ie. public pages versus rest of site)

![Middleware](http://www.slimframework.com/docs/images/middleware.png)

Middleware requires two methods called 'before' and 'after'.  These accept three parameters. First is the controller itself which allows you to get route information.  The second is the request collection, which can be used for passing information throughout the application.  The third is any parameters you passed to the middleware when using addMiddleware().  To use an application wide middleware, you would attach it directly to the MicroCF Class.

    var micro = application.require('micro');
    micro.addMiddleware('middleware.authentication');

__As a general rules, I suggest keeping your middleware in a single folder at the root directory called middleware.  You can add any hierarchical folder structure inside the controller folder to keep things organized.__

To add a route specific middleware, you can apply it to the route itself:

    micro.addRoute('GET', '/', 'controllers.Index.home').addMiddleware('middleware.index');

Or, since addRoute returns and instance of the route, you can assign a middleware later during your application

    var route = micro.addRoute('GET', '/', 'controllers.Index.home');
    if(true){
        route.addMiddleware('middleware.index');
    }

###NotFound ie 404

When you want to fall back gracefully and render a 404 error page, or even redirect when not found to another page, you can use the notFound method.  This method allows you to add a final controller and method for when a route isn't matched.

    var micro = application.require('micro');
    micro.addRoute('GET', '/', 'controllers.Index.home');
    micro.notFound('controller.Index.fourOhFour');
    micro.run();

###Running MicroCF

After you have applied all your routes, middleware and your notFound page, you still need to call one last method that run MicroCF.  This is the run method. (See Previous Examples)

##Example



-----

For this example, we will be using MicroCF - Our Micro Framework for creating a simple web site.

    cfpm micro

-----

file: ***application.cfc***

    component {
        application.cfpm = new cfpm();
    }

-----

file: ***index.cfm***

    <cfscript>
    micro = application.cfpm.require('micro',{baseDir: GetDirectoryFromPath(GetCurrentTemplatePath())});
    micro.addRoute('GET', '/', 'controllers.Index.home');
    micro.notFound('controllers.Index.fourOhFour');
    micro.run();
    return true;
    </cfscript>

-----

file: ***controllers/index.cfc***

    component {
        function home(rc){
            WriteOutput('Hello World');
        }
        function fourOhFour(rc){
            WriteOutput('Oh No! Page Not Found.');
        }
    }

