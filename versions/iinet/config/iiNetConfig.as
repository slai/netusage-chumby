import netusage.config.BasicButton;
import netusage.widgets.MessageOverlay;
import netusage.config.WidgetParameters;
import netusage.util.StringUtil;
import com.chumby.util.MCUtil;
import com.chumby.util.Delegate;

/**
 * Configuration dialog for iiNet net usage widget.
 * 
 * @author Samuel Lai
 */
class iiNetConfig extends MovieClip
{
	//{ static constants
	private static var MC_WIDTH:Number = 320;
	private static var MC_HEIGHT:Number = 240;
	//}
	
	//{ constants
	private var ISP_LOGO_DEPTH:Number = 1;
	private var INFOTEXT_DEPTH:Number = 2;
	
	private var USERNAMETEXT_DEPTH:Number = 10;
	private var USERNAMEINPUT_DEPTH:Number = 11;
	private var PASSWORDTEXT_DEPTH:Number = 12;
	private var PASSWORDINPUT_DEPTH:Number = 13;
	private var ACCOUNTNAMETEXT_DEPTH:Number = 14;
	private var ACCOUNTNAMEINPUT_DEPTH:Number = 15;
	
	private var SAVEBUTTON_DEPTH:Number = 20;
	private var CANCELBUTTON_DEPTH:Number = 21;
	
	private var MESSAGEOVERLAY_DEPTH:Number = 1000;
	
	private var HEADER_HEIGHT:Number = 54;
	//}
	
	//{ instance variables
	private var _usernameInput:TextField;
	private var _passwordInput:TextField;
	private var _accountNameInput:TextField;
	
	private var _messageOverlay:MessageOverlay;
	//}
	
	//-------------------------------------------------------------------
	// MTASC starts with this entry point
	public static function main()
	{
		//load UI
		var mainMC:MovieClip = MCUtil.CreateWithClass(iiNetConfig, _root, "main", 1);
	}
	
	public function iiNetConfig()
	{
		//create UI
		generateUI();
		
		//load parameters
		//TEST
		//showMessageOverlay("testing", _root._chumby_instance_url);
		showMessageOverlay("loading parameters", "contacting chumby servers...");
		WidgetParameters.getWidgetParameters(Delegate.create(this, loadedParameters));
	}
	
	private function generateUI():Void
	{
		var curTextField:TextField = null;
		var tf:TextFormat = null;
		var curY:Number = 0;
		
		//isp logo
		var ispLogo:MovieClip = this.attachMovie("ispLogo", "ispLogo", ISP_LOGO_DEPTH);
		ispLogo._x = 10 /* gap */;
		ispLogo._y = curY;
		
		//work out scaling factor
		var ispLogoScalingFactor:Number = ispLogo._width / ispLogo._height;
		ispLogo._width = (HEADER_HEIGHT - 10 /* gap */) * ispLogoScalingFactor;
		ispLogo._height = (HEADER_HEIGHT - 10 /* gap */);
		curY += HEADER_HEIGHT;
		
		tf = new TextFormat();
		with (tf)
		{
			font = "Arial";
			size = 13;
			color = 0x999999;
		}
		
		//info
		curTextField = createTextField("infoText", INFOTEXT_DEPTH, ispLogo._x + ispLogo._width + 10 /* gap */, 5 /* gap */, 
									   MC_WIDTH - ispLogo._x - ispLogo._width - 10 /* x-gap */, HEADER_HEIGHT - 5 /* y-gap */);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Not endorsed by iiNet (tm).\nOnly for ADSL plans.";
		curTextField.multiline = true;
		
		tf.color = 0x000000;
		
		//username
		curTextField = createTextField("usernameText", USERNAMETEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Username (required):";
		curY += 20 /* height of username text */;
		
		_usernameInput = createTextField("usernameInput", USERNAMEINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_usernameInput.setNewTextFormat(tf);
		_usernameInput.border = true;
		_usernameInput.type = "input";
		curY += 20 /* height of username input */;
		
		//password
		curY += 10 /* gap */;
		curTextField = createTextField("passwordText", PASSWORDTEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Password (required):";
		curY += 20 /* height of password text */;
		
		_passwordInput = createTextField("passwordInput", PASSWORDINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_passwordInput.setNewTextFormat(tf);
		_passwordInput.border = true;
		_passwordInput.type = "input";
		_passwordInput.password = true;
		curY += 20 /* height of password input */;
		
		//account name
		curY += 10 /* gap */;
		curTextField = createTextField("accountNameText", ACCOUNTNAMETEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Account name (optional):";
		curY += 20 /* height of account name text */;
		
		_accountNameInput = createTextField("accountNameInput", ACCOUNTNAMEINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_accountNameInput.setNewTextFormat(tf);
		_accountNameInput.border = true;
		_accountNameInput.type = "input";
		curY += 20 /* height of account name input */;
		
		//save button
		curY += 10 /* gap */;
		var button:MovieClip = MCUtil.CreateWithClass(BasicButton, this, "saveButton", SAVEBUTTON_DEPTH, { _x:10, _y:curY }, ["Save"]);
		button.onPress = Delegate.create(this, saveButtonClicked);
		
		//cancel button
		button = MCUtil.CreateWithClass(BasicButton, this, "cancelButton", CANCELBUTTON_DEPTH, { _x:70, _y:curY }, ["Cancel"]);
		button.onPress = Delegate.create(this, cancelButtonClicked);
		
	}
	
	private function loadedParameters(parameters:Object):Void
	{
		//for (var i in parameters)
		//	trace(i + ": " + parameters[i]);
		
		//check for error
		if (parameters["error"] == true)
		{
			showMessageOverlay("an error occurred.", "could not contact chumby servers.");
			return;
		}
		
		//no error, fill text boxes
		if (parameters["_private_netusage_iinet_username"] != undefined)
			_usernameInput.text = parameters["_private_netusage_iinet_username"];
			
		if (parameters["_private_netusage_iinet_password"] != undefined)
			_passwordInput.text = parameters["_private_netusage_iinet_password"];
		
		if (parameters["_private_netusage_iinet_accname"] != undefined)
			_accountNameInput.text = parameters["_private_netusage_iinet_accname"];
			
		removeMessageOverlay();
	}
	
	private function saveButtonClicked():Void
	{
		//validate
		var failedValidation:Boolean = false;
		if (StringUtil.isNullOrEmpty(_usernameInput.text))
		{
			failedValidation = true;
			_usernameInput.background = true;
			_usernameInput.backgroundColor = 0xFFFF00;
		}
		if (StringUtil.isNullOrEmpty(_passwordInput.text))
		{
			failedValidation = true;
			_passwordInput.background = true;
			_passwordInput.backgroundColor = 0xFFFF00;
		}
		
		if (failedValidation)
			return;
		
		//send parameters
		showMessageOverlay("saving parameters", "sending to chumby servers...");
		WidgetParameters.setWidgetParameters(Delegate.create(this, saveCompleted), 
			{
				_private_netusage_iinet_username : _usernameInput.text,
				_private_netusage_iinet_password : _passwordInput.text,
				_private_netusage_iinet_accname : _accountNameInput.text
			}
		);
	}
	
	private function saveCompleted(success:Boolean):Void
	{
		WidgetParameters.closeConfigDialog();
	}
	
	private function cancelButtonClicked():Void
	{
		WidgetParameters.closeConfigDialog();
	}
	
	//{ message overlay functions
	private function isMessageOverlayShowing():Boolean
	{
		return _messageOverlay != null;
	}
	
	private function showMessageOverlay(messageTitle:String, message:String):Void
	{
		if (!isMessageOverlayShowing())
		{
			//does not exist, create it
			//keep header and account name showing
			_messageOverlay = 
					MCUtil.CreateWithClass(
							MessageOverlay, this, "messageOverlay", MESSAGEOVERLAY_DEPTH, { _y:HEADER_HEIGHT } );
							
			//attach handlers
			_messageOverlay.onClicked = Delegate.create(this, messageOverlayClicked);
		}
		
		//set messages
		_messageOverlay.messageTitle = messageTitle;
		_messageOverlay.message = message;
	}
	
	private function removeMessageOverlay():Void
	{
		if (_messageOverlay != null)
		{
			_messageOverlay.removeOverlay();
			_messageOverlay.removeMovieClip();
			_messageOverlay = null;
		}
	}
	
	private function messageOverlayClicked():Void
	{
		//not used
	}
	//}
	
}