component {

	this.middleware = [];
	this.params = [];
	this.paramValues = {};

	public function init(HTTPMethod, URLRoute, controller){
		this.URLRoute = arguments.URLRoute;
		this.controllerMethod = parseMethod(controller);
		this.controllerClass = parseClass(controller, this.controllerMethod);
		return this;
	}
	public function getURL(){
		return this.URLRoute;
	}

	public function matchURL(currentURL){
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

	public function addMiddleware(middleware){
		ArrayAppend(this.middleware, arguments.middleware);
		return this;
	}

	public function run(requestCollection){
		for(var class in this.middleware){
			this.middlewareClasses[class] = new '#class#'();
			this.middlewareClasses[class].before(arguments.requestCollection);
		}

		for(param in this.params){
			this.controllerClass = this.controllerClass.replace(param, this.paramValues[param]);
			this.controllerMethod = this.controllerMethod.replace(param, this.paramValues[param]);
		}
		var controller = new '#this.controllerClass#'();
		controller[this.controllerMethod](arguments.requestCollection, this.paramValues);

		for(var i = ArrayLen(this.middleware); i >= 1; i--){
			this.middlewareClasses[this.middleware[i]].after(arguments.requestCollection);
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