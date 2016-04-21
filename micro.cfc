component {

	this.routes = [];
	this.middleware = [];
	this.middlewareParams = {};
	this.requestCollection = {};
	this.notFoundMethod = '';
	this.notFoundController = '';

	public function init(params){
		this.requestCollection.baseDir = StructKeyExists(params, 'baseDir') ? params.baseDir : GetDirectoryFromPath(GetCurrentTemplatePath()) & '../../';
		return this;
	}

	public function addRoute(HTTPMethod, URLRoute, controller){
		var route = new route(HTTPMethod, URLRoute, controller);
		for(var class in this.middleware){
			route.addMiddleware(class, this.middlewareParams[class]);
		}
		ArrayAppend(this.routes, route);
		return route;
	}

	public function addMiddleware(middleware, params = {}){
		ArrayAppend(this.middleware, arguments.middleware);
		this.middlewareParams[arguments.middleware] = arguments.params;
		return this;
	}

	public function removeMiddleware(middleware){
		ArrayDelete(this.middleware, arguments.middleware);
		return this;
	}

	public function run(){
		var routeFound = false;

		var currentRoute = CGI.REQUEST_URL.replace(CGI.HTTP_HOST,'').replace('http://','').replace('https://', '');
		var pos = FindNoCase('.cfm', currentRoute);
		if(pos > 1){
			currentRoute = RemoveChars(currentRoute, 1, pos + 3);
		}
		currentRoute = listToArray(currentRoute,'?')[1];
		this.requestCollection.path = currentRoute;

		for(var route in this.routes){
			if(route.matchURL(currentRoute)){
				routeFound = true;
				route.run(this.requestCollection);
			}
		}
		if(!routeFound){
			if(this.notFoundController != '' && this.notFoundMethod != ''){
				for(var i = ArrayLen(this.middleware); i >= 1; i--){
					var middleware = this.middleware[i];
					this.middlewareClasses[middleware] = new '#middleware#'();
					this.middlewareClasses[middleware].before(this.notFoundController, this.requestCollection, this.middlewareParams[middleware]);
				}
				var notFound = new "#this.notFoundController#"();
				notFound[this.notFoundMethod](this.requestCollection);
				for(var i = 1; i <= ArrayLen(this.middleware); i++){
					var middleware = this.middleware[i];
					this.middlewareClasses[middleware].after(this.notFoundController, this.requestCollection, this.middlewareParams[middleware]);
				}
			}else{
				throw(msg="Route not found, 404");
			}
		}

	}

	public function notFound(controller){
		this.notFoundMethod = parseMethod(controller);
		this.notFoundController = parseClass(controller, this.notFoundMethod);
	}

	private function parseMethod(controller){
		var split = ListToArray(arguments.controller, '.');
		return ArrayLen(split) > 1 ? split[ArrayLen(split)] : 'index';
	}

	private function parseClass(controller, method){
		var split = ListToArray(arguments.controller, '.');
		if(split[ArrayLen(split)] == method){
			ArrayDeleteAt(split, ArrayLen(split));
		}
		return ArrayToList(split, '.');
	}

}