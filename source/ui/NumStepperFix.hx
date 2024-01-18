package ui;

import flixel.FlxSprite;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI.NamedFloat;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITypedButton;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxStringUtil;

/**
 * FlxUINumericStepper fork that adds a callback.
 */
class NumStepperFix extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams
{
	public var button_plus:FlxUITypedButton<FlxSprite>;
	public var button_minus:FlxUITypedButton<FlxSprite>;
	private var text_field:FlxText;

	public var stepSize:Float = 0;
	public var decimals(default, set):Int = 0; // Number of decimals
	public var min(default, set):Float = 0;
	public var max(default, set):Float = 10;
	public var value(default, set):Float = 0;
	public var stack(default, set):Int = STACK_HORIZONTAL;
	public var isPercent(default, set):Bool = false;

	public static inline var STACK_VERTICAL:Int = 0;
	public static inline var STACK_HORIZONTAL:Int = 1;

	public static inline var CLICK_EVENT:String = "click_numeric_stepper"; // click a numeric stepper button
	public static inline var EDIT_EVENT:String = "edit_numeric_stepper"; // edit the numeric stepper text field
	public static inline var CHANGE_EVENT:String = "change_numeric_stepper"; // do either of the above

	public var params(default, set):Array<Dynamic>;

	public var callback:Float->Void;

	/**
	 * If true, when buttons of this numerical stepper
	 * are pushed, it will add/subtract on continuously.
	 */
	public var holdable:Bool = true;
	public var holdMax:Float = 0.5;

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		params = p;
		return params;
	}

	public var skipButtonUpdate(default, set):Bool;

	private function set_skipButtonUpdate(b:Bool):Bool
	{
		skipButtonUpdate = b;
		button_plus.skipButtonUpdate = b;
		button_minus.skipButtonUpdate = b;
		// TODO: Handle input text
		return b;
	}

	private override function set_color(Value:Int):Int
	{
		color = Value;
		button_plus.color = Value;
		button_minus.color = Value;
		if ((text_field is FlxInputText))
		{
			var fit:FlxInputText = cast text_field;
			fit.backgroundColor = Value;
		}
		else
		{
			text_field.color = Value;
		}
		return Value;
	}

	private function set_min(f:Float):Float
	{
		min = f;
		if (value < min)
		{
			value = min;
		}
		return min;
	}

	private function set_max(f:Float):Float
	{
		max = f;
		if (value > max)
		{
			value = max;
		}
		return max;
	}

	private function set_value(f:Float):Float
	{
		value = f;
		if (value < min)
		{
			value = min;
		}
		if (value > max)
		{
			value = max;
		}
		if (text_field != null)
		{
			var displayValue:Float = value;
			if (isPercent)
			{
				displayValue *= 100;
				text_field.text = Std.string(decimalize(displayValue, decimals)) + "%";
			}
			else
			{
				text_field.text = decimalize(displayValue, decimals);
			}
		}
		return value;
	}

	private function set_decimals(i:Int):Int
	{
		decimals = i;
		if (i < 0)
		{
			decimals = 0;
		}
		value = value;
		return decimals;
	}

	private function set_isPercent(b:Bool):Bool
	{
		isPercent = b;
		value = value;
		return isPercent;
	}

	private function set_stack(s:Int):Int
	{
		stack = s;
		var btnSize:Int = 10;
		var offsetX:Int = 0;
		var offsetY:Int = 0;
		if ((text_field is FlxUIInputText))
		{
			offsetX = 1;
			offsetY = 1; // border for input text
		}
		switch (stack)
		{
			case STACK_HORIZONTAL:
				btnSize = 2 + cast text_field.height;
				if (button_plus.height != btnSize)
				{
					button_plus.resize(btnSize, btnSize);
				}
				if (button_minus.height != btnSize)
				{
					button_minus.resize(btnSize, btnSize);
				}
				button_plus.x = offsetX + text_field.x + text_field.width;
				button_plus.y = -offsetY + text_field.y;
				button_minus.x = button_plus.x + button_plus.width;
				button_minus.y = button_plus.y;
			case STACK_VERTICAL:
				btnSize = 1 + cast text_field.height / 2;
				if (button_plus.height != btnSize)
				{
					button_plus.resize(btnSize, btnSize);
				}
				if (button_minus.height != btnSize)
				{
					button_minus.resize(btnSize, btnSize);
				}
				button_plus.x = offsetX + text_field.x + text_field.width;
				button_plus.y = -offsetY + text_field.y;
				button_minus.x = offsetX + text_field.x + text_field.width;
				button_minus.y = offsetY + text_field.y + (text_field.height - button_minus.height);
		}
		return stack;
	}

	private inline function decimalize(f:Float, digits:Int):String
	{
		var tens:Float = Math.pow(10, digits);
		return Std.string(Math.round(f * tens) / tens);
	}

	/**
	 * This creates a new dropdown menu.
	 *
	 * @param	X					x position of the dropdown menu
	 * @param	Y					y position of the dropdown menu
	 * @param	StepSize			How big is the step
	 * @param	DefaultValue		Optional default numerical value for the stepper to display
	 * @param	Min					Optional Minimum values for the stepper
	 * @param	Max					Optional Maximum and Minimum values for the stepper
	 * @param	Decimals			Optional # of decimal places
	 * @param	Stack				Stacking method
	 * @param	TextField			Optional text field
	 * @param	ButtonPlus			Optional button to use for plus
	 * @param	ButtonMinus			Optional button to use for minus
	 * @param	IsPercent			Whether to portray the number as a percentage
	 */
	public function new(X:Float = 0, Y:Float = 0, StepSize:Float = 1, DefaultValue:Float = 0, Min:Float = -999, Max:Float = 999, Decimals:Int = 0,
			Stack:Int = STACK_HORIZONTAL, ?TextField:FlxText, ?ButtonPlus:FlxUITypedButton<FlxSprite>, ?ButtonMinus:FlxUITypedButton<FlxSprite>,
			IsPercent:Bool = false)
	{
		super(X, Y);

		if (TextField == null)
		{
			TextField = new InputTextFix(0, 0, 25);
		}
		TextField.x = 0;
		TextField.y = 0;
		text_field = TextField;
		text_field.text = Std.string(DefaultValue);

		if ((text_field is FlxUIInputText))
		{
			var fuit:FlxUIInputText = cast text_field;
			fuit.lines = 1;
			fuit.callback = _onInputTextEvent; // internal communication only
			fuit.broadcastToFlxUI = false;
		}

		if ((text_field is InputTextFix))
		{
			var fuit:InputTextFix = cast text_field;
			fuit.callback = _onInputTextEvent; // internal communication only
		}

		stepSize = StepSize;
		decimals = Decimals;
		min = Min;
		max = Max;
		value = DefaultValue;
		isPercent = IsPercent;

		var btnSize:Int = 1 + cast TextField.height;

		if (ButtonPlus == null)
		{
			ButtonPlus = new FlxUITypedButton<FlxSprite>(0, 0);
			ButtonPlus.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], btnSize, btnSize, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON_THIN)],
				FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
			ButtonPlus.label = new FlxSprite(0, 0, FlxUIAssets.IMG_PLUS);
		}
		if (ButtonMinus == null)
		{
			ButtonMinus = new FlxUITypedButton<FlxSprite>(0, 0);
			ButtonMinus.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], btnSize, btnSize, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON_THIN)],
				FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
			ButtonMinus.label = new FlxSprite(0, 0, FlxUIAssets.IMG_MINUS);
		}

		button_plus = ButtonPlus;
		button_minus = ButtonMinus;

		add(text_field);
		add(button_plus);
		add(button_minus);

		button_plus.onUp.callback = _onPlus;
		button_plus.onDown.callback = function() {
			buttonPlusPushed = true;
		}
		button_plus.onOut.callback = function() {
			buttonPlusPushed = false;
		}
		button_plus.broadcastToFlxUI = false;

		button_minus.onUp.callback = _onMinus;
		button_minus.onDown.callback = function() {
			buttonMinusPushed = true;
		}
		button_minus.onOut.callback = function() {
			buttonMinusPushed = false;
		}
		button_minus.broadcastToFlxUI = false;

		stack = Stack;
	}

	private function _onInputTextEvent(text:String, action:String):Void
	{
		if (text == "")
		{
			text = Std.string(min);
		}

		var numDecimals:Int = 0;
		for (i in 0...text.length)
		{
			var char = text.charAt(i);
			if (char == ".")
			{
				numDecimals++;
			}
		}

		var justAddedDecimal = (numDecimals == 1 && text.indexOf(".") == text.length - 1);

		// if I just added a decimal don't treat that as having changed the value just yet
		if (!justAddedDecimal)
		{
			value = Std.parseFloat(text);
			_doCallback(EDIT_EVENT);
			_doCallback(CHANGE_EVENT);
		}
	}

	private function _onPlus():Void
	{
		value += stepSize;
		_doCallback(CLICK_EVENT);
		_doCallback(CHANGE_EVENT);

		buttonPlusPushed = addedContinuously = false;
	}

	private function _onMinus():Void
	{
		value -= stepSize;
		_doCallback(CLICK_EVENT);
		_doCallback(CHANGE_EVENT);

		buttonMinusPushed = addedContinuously = false;
	}

	private function _doCallback(event_name:String):Void
	{
		if (broadcastToFlxUI)
		{
			FlxUI.event(event_name, this, value, params);
		}

		if (callback != null)
			callback(value);
	}

	var buttonPlusPushed:Bool = false;
	var buttonMinusPushed:Bool = false;
	var addedContinuously:Bool = false;

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (holdable)
		{
			if (buttonPlusPushed || buttonMinusPushed)
			{
				if (holdTime > holdMax)
				{
					addedContinuously = true;

					if (buttonPlusPushed)
					{
						value += stepSize;
						_doCallback(CLICK_EVENT);
						_doCallback(CHANGE_EVENT);
					}
					
					if (buttonMinusPushed)
					{
						value -= stepSize;
						_doCallback(CLICK_EVENT);
						_doCallback(CHANGE_EVENT);
					}
				}
				else
					holdTime += elapsed;
			}
			else 
				holdTime = 0;
		}
	}
}