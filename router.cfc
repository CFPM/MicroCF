component {

	this.routes = [];
	this.middleware = [];
	this.requestCollection = {};
	this.notFoundMethod = '';
	this.notFoundController = '';

	public function init(){
		return this;
	}

	public function addRoute(HTTPMethod, URLRoute, controller){
		var route = new route(HTTPMethod, URLRoute, controller);
		ArrayAppend(this.routes, route);
		return route;
	}

	public function addMiddleware(middleware){
		ArrayAppend(this.middleware, arguments.middleware);
		return this;
	}

	public function run(){
		var routeFound = false;
		for(var class in this.middleware){
			this.middlewareClasses[class] = new '#class#'();
			this.middlewareClasses[class].before(this.requestCollection);
		}

		var currentRoute = CGI.REQUEST_URL.replace(CGI.HTTP_HOST,'').replace('http://','').replace('https://', '');
		var pos = FindNoCase('.cfm', currentRoute);
		if(pos > 1){
			currentRoute = RemoveChars(currentRoute, 1, pos + 3);
		}
		currentRoute = listToArray(currentRoute,'?')[1];
		for(var route in this.routes){
			if(route.matchURL(currentRoute)){
				routeFound = true;
				route.run(this.requestCollection);
			}
		}
		if(!routeFound){
			if(this.notFoundController != '' && this.notFoundMethod != ''){
				var notFound = new "#this.notFoundController#"();
				notFound[this.notFoundMethod](this.requestCollection);
			}else{
				throw(msg="Route not found, 404");
			}
		}


		for(var i = ArrayLen(this.middleware); i >= 1; i--){
			this.middlewareClasses[this.middleware[i]].after(this.requestCollection);
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