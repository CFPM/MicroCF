component {

	this.middleware = [];
	this.middlewareParams = {};
	this.params = [];
	this.paramValues = {};

	public function init(HTTPMethod, URLRoute, controller){
		this.HTTPMethod = arguments.HTTPMethod;
		this.URLRoute = arguments.URLRoute;
		this.controllerMethod = parseMethod(controller);
		this.controllerClass = parseClass(controller, this.controllerMethod);
		return this;
	}
	public function getURL(){
		return this.URLRoute;
	}

	public function matchURL(currentURL){
		if(CGI.REQUEST_METHOD != this.HTTPMethod){
			return false;
		}
		this.regexRoute = this.URLRoute;
		var output = REFind("{([^}]*)}", this.regexRoute, 1, true);
		while(StructKeyExists(output, 'pos') && output.pos[1] != 0){
			var param = Mid(this.regexRoute, output.pos[1], output.len[1]);
			ArrayAppend(this.params, param);
			this.regexRoute = this.regexRoute.replace(param, '([a-zA-Z0-9]+)');
			output = REFind("{([^}]*)}", this.regexRoute, 1, true);
		}
		this.regexRoute = '^' & this.regexRoute & '$';
		var match = REMatch(this.regexRoute, currentURL);
		var output = REFind(this.regexRoute, currentURL, 1, true);
		if(ArrayLen(match) == 1){
			if(StructKeyExists(output, 'pos') && ArrayLen(output.pos) > 1){
				for(var i = 2; i <= ArrayLen(output.pos); i++){
					this.paramValues[this.params[i-1]] = Mid(currentURL, output.pos[i], output.len[i]);
				}
			}
			return true;
		}
		return false;
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

	public function run(requestCollection){
		for(param in this.params){
			this.controllerClass = this.controllerClass.replace(param, this.paramValues[param]);
			this.controllerMethod = this.controllerMethod.replace(param, this.paramValues[param]);
		}

		arguments.requestCollection.CONTROLLERCLASS = this.CONTROLLERCLASS;
		arguments.requestCollection.CONTROLLERMETHOD = this.CONTROLLERMETHOD;
		arguments.requestCollection.HTTPMETHOD = this.HTTPMETHOD;
		arguments.requestCollection.PARAMS = this.PARAMS;
		arguments.requestCollection.URLROUTE = this.URLROUTE;
		arguments.requestCollection.PARAMVALUES = this.PARAMVALUES;

		var controller = new '#this.controllerClass#'();

		for(var i = ArrayLen(this.middleware); i >= 1; i--){
			var middleware = this.middleware[i];
			this.middlewareClasses[middleware] = new '#middleware#'();
			this.middlewareClasses[middleware].before(controller, arguments.requestCollection, this.middlewareParams[middleware]);
		}

		controller[this.controllerMethod](arguments.requestCollection, this.paramValues);

		for(var i = 1; i <= ArrayLen(this.middleware); i++){
			var middleware = this.middleware[i];
			this.middlewareClasses[middleware].after(controller, arguments.requestCollection, this.middlewareParams[middleware]);
		}
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