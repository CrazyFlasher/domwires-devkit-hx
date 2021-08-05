package com.domwires.ext.service.net;

import com.domwires.core.mvc.model.IModel;
import com.domwires.core.mvc.model.AbstractModel;

class RequestVo
{
	public var url(get, never):String;
	public var type(get, never):EnumValue;

	private var _url:String;
	private var _type:EnumValue;

	public function new(url:String, type:EnumValue) {
		_url = url;
		_type = type;
	}

	@PostConstruct
	private function init():Void {}

	private function get_url():String {
		return _url;
	}

	private function get_type():EnumValue {
		return _type;
	}
}
