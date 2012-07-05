package creacog.spark.events
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import spark.events.TitleWindowBoundsEvent;
	
	public class TitleWindowBoundsEvent extends spark.events.TitleWindowBoundsEvent
	{
/**
 *  The <code>TitleWindowBoundsEvent.WINDOW_RESIZE_START</code> constant defines the value of the
 *  <code>type</code> property of the event object for a <code>windowResizeStart</code> event.
 *
 *  <p>The properties of the event object have the following values:</p>
 *  <table class="innertable">
 *     <tr><th>Property</th><th>Value</th></tr>
 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
 *     <tr><td><code>cancelable</code></td><td>true</td></tr>
 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
 *       event listener that handles the event. For example, if you use
 *       <code>myButton.addEventListener()</code> to register an event listener,
 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
 *     <tr><td><code>beforeBounds</code></td><td>The starting bounds of the object.</td></tr>
 *     <tr><td><code>afterBounds</code></td><td>null</td></tr>
 *     <tr><td><code>target</code></td><td>The Object that dispatched the event;
 *       it is not always the Object listening for the event.
 *       Use the <code>currentTarget</code> property to always access the
 *       Object listening for the event.</td></tr>
 *  </table>
 *
 *  @eventType windowMoveStart
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
	public static const WINDOW_RESIZE_START:String = "windowResizeStart";
	
/**
 *  The <code>TitleWindowBoundsEvent.WINDOW_RESIZING</code> constant defines the value of the
 *  <code>type</code> property of the event object for a <code>windowResizing</code> event.
 *
 *  <p>The properties of the event object have the following values:</p>
 *  <table class="innertable">
 *     <tr><th>Property</th><th>Value</th></tr>
 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
 *     <tr><td><code>cancelable</code></td><td>true</td></tr>
 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
 *       event listener that handles the event. For example, if you use
 *       <code>myButton.addEventListener()</code> to register an event listener,
 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
 *     <tr><td><code>beforeBounds</code></td><td>The starting bounds of the object.</td></tr>
 *     <tr><td><code>afterBounds</code></td><td>null</td></tr>
 *     <tr><td><code>target</code></td><td>The Object that dispatched the event;
 *       it is not always the Object listening for the event.
 *       Use the <code>currentTarget</code> property to always access the
 *       Object listening for the event.</td></tr>
 *  </table>
 *
 *  @eventType windowMoveStart
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
	public static const WINDOW_RESIZING:String = "windowResizing";

/**
 *  The <code>TitleWindowBoundsEvent.WINDOW_RESIZE</code> constant defines the value of the
 *  <code>type</code> property of the event object for a <code>windowResize</code> event.
 *
 *  <p>The properties of the event object have the following values:</p>
 *  <table class="innertable">
 *     <tr><th>Property</th><th>Value</th></tr>
 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
 *     <tr><td><code>cancelable</code></td><td>true</td></tr>
 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
 *       event listener that handles the event. For example, if you use
 *       <code>myButton.addEventListener()</code> to register an event listener,
 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
 *     <tr><td><code>beforeBounds</code></td><td>The starting bounds of the object.</td></tr>
 *     <tr><td><code>afterBounds</code></td><td>null</td></tr>
 *     <tr><td><code>target</code></td><td>The Object that dispatched the event;
 *       it is not always the Object listening for the event.
 *       Use the <code>currentTarget</code> property to always access the
 *       Object listening for the event.</td></tr>
 *  </table>
 *
 *  @eventType windowMoveStart
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
	public static const WINDOW_RESIZE:String = "windowResize";

/**
 *  The <code>TitleWindowBoundsEvent.WINDOW_RESIZE_END</code> constant defines the value of the
 *  <code>type</code> property of the event object for a <code>windowResizeEnd</code> event.
 *
 *  <p>The properties of the event object have the following values:</p>
 *  <table class="innertable">
 *     <tr><th>Property</th><th>Value</th></tr>
 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
 *     <tr><td><code>cancelable</code></td><td>true</td></tr>
 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
 *       event listener that handles the event. For example, if you use
 *       <code>myButton.addEventListener()</code> to register an event listener,
 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
 *     <tr><td><code>beforeBounds</code></td><td>The starting bounds of the object.</td></tr>
 *     <tr><td><code>afterBounds</code></td><td>null</td></tr>
 *     <tr><td><code>target</code></td><td>The Object that dispatched the event;
 *       it is not always the Object listening for the event.
 *       Use the <code>currentTarget</code> property to always access the
 *       Object listening for the event.</td></tr>
 *  </table>
 *
 *  @eventType windowMoveStart
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
	public static const WINDOW_RESIZE_END:String = "windowResizeEnd";
	
	
/**
 *  Constructor.
 * 
 *  Extends spark.events.TitleWindowBoundsEvent to include resize of the title window
 *
 *  @param type The event type; indicates the action that caused the event.
 *
 *  @param bubbles Specifies whether the event can bubble
 *  up the display list hierarchy.
 *
 *  @param cancelable Specifies whether the behavior
 *  associated with the event can be prevented.
 *
 *  @param beforeBounds The bounds of the window before the action. If
 *      this event is cancelable, <code>beforeBounds</code> is the current bounds of
 *      the window. Otherwise, it is the bounds before a change occurred.
 *
 *  @param afterBounds The bounds of the window after the action. If
 *      this event is cancelable, <code>afterBounds</code> is the future bounds of
 *      the window. Otherwise, it is the current bounds.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */	
		public function TitleWindowBoundsEvent( type		:String,
												bubbles		:Boolean = false,
												cancelable	:Boolean = false,
												beforeBounds:Rectangle = null,
												afterBounds	:Rectangle = null )
		{
			super(	type,
					bubbles,
					cancelable,
					beforeBounds,
					afterBounds );
		}
	}
}