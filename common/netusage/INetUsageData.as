/**
 * Interface for getting net usage data. To be implemented in each version (ISP).
 * 
 * @author Samuel Lai
 */
interface netusage.INetUsageData 
{
	function init():Void;
	
	function start():Void;
	function hasStarted():Boolean;
	
	//loads logo into target, returning itself
	function loadLogo(target:MovieClip, instanceName:String, depth:Number):MovieClip;
	
	function getLastUpdated():Date;
	function setOnUpdated(f:Function):Void;
	function setOnError(f:Function):Void; //has a String parameter with error message.
	
	function getAccountName():String;
	
	function getRolloverDate():Date;
	
	function hasOffPeak():Boolean;
	//returns true if currently in peak period. If no off-peak period, return true always.
	function isPeak():Boolean;
	
	//in MB
	function getPeakDataUsed():Number;
	//in MB
	function getPeakDataQuota():Number;
	//in cents
	function getPeakExcessCost():Number;
	
	//in MB
	function getOffPeakDataUsed():Number;
	//in MB
	function getOffPeakDataQuota():Number;
	//in cents
	function getOffPeakExcessCost():Number;
}