package creacog.spark.components
{
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

import mx.core.UIComponent;
import mx.events.SandboxMouseEvent;

import spark.components.TitleWindow;

import creacog.spark.events.TitleWindowBoundsEvent;

/**
 *  Dispatched when the user grabs the resizeHandle.
 *
 *  @eventType  creacog.spark.events.TitleWindowBoundsEvent.WINDOW_RESIZE_START
 */
[Event(name="windowResizeStart", type="creacog.spark.events.TitleWindowBoundsEvent")]

/**
 *  Dispatched when the user tries to resize the TitleWindow.
 *
 *  @eventType creacog.spark.events.TitleWindowBoundsEvent.WINDOW_RESIZING
 */
[Event(name="windowResizing", type="creacog.spark.events.TitleWindowBoundsEvent")]

/**
 *  Dispatched when the user has successfully resized the
 *  TitleWindow.
 *
 *  @eventType creacog.spark.events.TitleWindowBoundsEvent.WINDOW_RESIZE
 */
[Event(name="windowResize", type="creacog.spark.events.TitleWindowBoundsEvent")]

/**
 *  Dispatched when the user releases the resizeHandle.
 *
 *  @eventType creacog.spark.events.TitleWindowBoundsEvent.WINDOW_RESIZE_END
 */
[Event(name="windowResizeEnd", type="creacog.spark.events.TitleWindowBoundsEvent")]

/**
 *  Resizing State when resizing the component.
 */
[SkinState("resizing")]

/**
 *  The ResizeableTitleWindow class extends TitleWindow to include
 *  a resize handle. Implements the specification as close as possible
 *  to that described on opensource.adobe.com...
 * 	http://opensource.adobe.com/wiki/display/flexsdk/Spark+TitleWindow
 * 
 * <p>Note: It is assumed that the resizeHandle is positioned relative to
 * and acts relative to the bottom right corner of the component</p> 
 * 
 *  <p>The ResizeableTitleWindow is designed as a pop-up window.
 *  Do not create a ResizeableTitleWindow in MXML as part of an application.
 *  Instead, you typically create a custom MXML component based on 
 *  the ResizeableTitleWindow class, and then use the 
 *  <code>PopUpManager.createPopUp()</code> method to pop up the component, 
 *  and the <code>PopUpManager.removePopUp()</code> method 
 *  to remove the component.</p>
 *  
 *  <p>The ResizeableTitleWindow container has the following default sizing characteristics:</p>
 *     <table class="innertable">
 *        <tr>
 *           <th>Characteristic</th>
 *           <th>Description</th>
 *        </tr>
 *        <tr>
 *           <td>Default size</td>
 *           <td>Height is large enough to hold all of the children in the content area at the default or 
 *               explicit heights of the children, plus the title bar and border, plus any vertical gap between 
 *               the children, plus the top and bottom padding of the container.<br/> 
 *               Width is the larger of the default or explicit width of the widest child, plus the left and 
 *               right container borders padding, or the width of the title text.</td>
 *        </tr>
 *        <tr>
 *           <td>Default skin class</td>
 *           <td>creacog.spark.skins.ResizeableTitleWindowSkin</td>
 *        </tr>
 *        <tr>
 *           <td>Mac layout skin class</td>
 *           <td>creacog.spark.skins.ResizeableTitleWindowMacSkin</td>
 *        </tr>
 *     </table>
 *  
 *  @mxml
 *  
 *  <p>The <code>&lt;s:ResizeableTitleWindow&gt;</code> tag inherits all of the tag 
 *  attributes of its superclass and adds the following tag attributes:</p>
 *  
 *  <pre>
 *  &lt;s:ResizeableTitleWindow&gt;
 *    <strong>Events</strong>
 *    windowResizeStart="<i>No default</i>"
 *    windowResizing="<i>No default</i>"
 *    windowResize="<i>No default</i>"
 *    windowResizeEnd="<i>No default</i>"
 *  &lt;/s:ResizeableTitleWindow&gt;
 *  </pre>
 *  
 *  @includeExample examples/SimpleTitleWindowExample.mxml -noswf
 *  @includeExample examples/TitleWindowApp.mxml
 *  
 *  @see spark.components.TitleWindow
 *  @see spark.skins.spark.TitleWindowSkin
 *  @see spark.skins.spark.TitleWindowCloseButtonSkin
 *  @see creacog.spark.skins.ResizeableTitleWindowSkin
 *  @see creacog.spark.skins.ResizeableTitleWindowMacSkin
 *  @see creacog.spark.skins.ResizeHandleSkin
 *  @see mx.managers.PopUpManager
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */	
	public class ResizeableTitleWindow extends TitleWindow
	{
/**
 *  @private
 *  Horizontal location where the user pressed the mouse button
 *  on the resizeHandle to start dragging, relative to the original
 *  horizontal location of the ResizeableTitleWindow.
 */
		private var startResizeX:Number;
/**
 *  @private
 *  Vertical location where the user pressed the mouse button
 *  on the resizeHandle to start dragging, relative to the original
 *  vertical location of the ResizeableTitleWindow.
 */
		private var startResizeY:Number;
 /**
 *  @private
 *  The starting bounds of the TitleWindow before a user
 *  moves or resizes it.
 */
		private var startBounds:Rectangle;
/**
 *  The skin part the defines the handle that
 *  is used to resize the TitleWindow.
 */
		[SkinPart(required="false")]
		public var resizeHandle:UIComponent;
/**
 *  Constructor.
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */		
		public function ResizeableTitleWindow()
		{
			super();
		}
		
		override protected function partAdded(	partName:String,
												instance:Object ):void
		{
			super.partAdded( 	partName,
								instance );
			
			if( instance == resizeHandle )
			{
				resizeHandle.addEventListener(	MouseEvent.MOUSE_DOWN,
												resizeHandle_mouseDownHandler );
			}
		}
		override protected function partRemoved(	partName:String,
													instance:Object ):void
		{
			super.partRemoved(	partName,
								instance );
			
			if( instance == resizeHandle )
			{
				resizeHandle.removeEventListener(	MouseEvent.MOUSE_DOWN,
													resizeHandle_mouseDownHandler );
			}
		}
/**
 * @private
 */
		override public function setActualSize(	w:Number, h:Number ):void
		{
			var beforeBounds:Rectangle = new Rectangle( x, y, width, height );
		
			super.setActualSize( w, h );
			
			// Dispatch "windowResize" event when ResizeableTitleWindow is resized.
			var afterBounds:Rectangle = new Rectangle( x, y, width, height);
			
			var e2:TitleWindowBoundsEvent =
				new TitleWindowBoundsEvent(	TitleWindowBoundsEvent.WINDOW_RESIZE,
											false,
											false,
											beforeBounds,
											afterBounds );
			
			dispatchEvent( e2 );
		}
/**
 *  Called when the user starts resizing a TitleWindow
 *  that has been popped up either by PopUpManager or
 *  PopUpAnchor.
 */
		protected function resizeHandle_mouseDownHandler( event:MouseEvent ):void
		{
	        // Only allow dragging of pop-upped windows
	        if (enabled && isPopUp)
	        {
	            // Store the mouse's start click
	            startResizeX = event.stageX;
	            startResizeY = event.stageY;
	            
	            var sbRoot:DisplayObject = systemManager.getSandboxRoot();
	            
	            sbRoot.addEventListener(	MouseEvent.MOUSE_MOVE,
											resizeHandle_mouseMoveHandler,
											true );
				
	            sbRoot.addEventListener(	MouseEvent.MOUSE_UP,
											resizeHandle_mouseUpHandler,
											true );
				
	            sbRoot.addEventListener(	SandboxMouseEvent.MOUSE_UP_SOMEWHERE,
											resizeHandle_mouseUpHandler )
	            
	            // add the mouse shield so we can drag over untrusted applications.
	            systemManager.deployMouseShields(true);
	        }
			
		}
/**
 *  Called when the user resizes a TitleWindow
 *  that has been popped up by either by PopUpManager or
 *  PopUpAnchor.
 */
		protected function resizeHandle_mouseMoveHandler( event:MouseEvent ):void
		{
	       // Check to see if this is the first mouseMove
	        if (!startBounds)
	        {
	            // First dispatch a cancellable "windowResizeStart" event
	            startBounds = new Rectangle(x, y, width, height);
				
	            var startEvent:TitleWindowBoundsEvent=
	                new TitleWindowBoundsEvent(	TitleWindowBoundsEvent.WINDOW_RESIZE_START,
	                  							false,
												true,
												startBounds,
												null );
				
	            dispatchEvent( startEvent );
	
	            if (startEvent.isDefaultPrevented())
	            {
	                // Clean up code if entire resize is canceled.
	                var sbRoot:DisplayObject = systemManager.getSandboxRoot();
	            
		            sbRoot.removeEventListener(	MouseEvent.MOUSE_MOVE,
												resizeHandle_mouseMoveHandler,
												true );
					
		            sbRoot.removeEventListener(	MouseEvent.MOUSE_UP,
												resizeHandle_mouseUpHandler,
												true );
					
		            sbRoot.removeEventListener(	SandboxMouseEvent.MOUSE_UP_SOMEWHERE,
												resizeHandle_mouseUpHandler )
		                
	                systemManager.deployMouseShields( false );
	                
	                startResizeX		= NaN;
	                startResizeY		= NaN;
	                startBounds	= null;
					
	                return;
	            }
	        }
			
	        // Dispatch cancelable "windowResizing" event with before and after bounds.
	        var beforeBounds:Rectangle = new Rectangle( x, y, width, height );
			
			// calculate target wide and height
			var targetWidth		:Number = startBounds.width		+ Math.round( event.stageX - startResizeX );
			var targetHeight	:Number = startBounds.height	+ Math.round( event.stageY - startResizeY );
			
			// avoid going too small
			targetWidth		= targetWidth	> minWidth	? targetWidth	: minWidth;
			targetHeight	= targetHeight	> minHeight	? targetHeight	: minHeight;
			
			//avoid going too large
			targetWidth		= targetWidth	< maxWidth	? targetWidth	: maxWidth;
			targetHeight	= targetHeight	< maxHeight	? targetHeight	: maxHeight;
		
	        var afterBounds:Rectangle = 
	            new Rectangle(	x,
								y,
								targetWidth,
	                          	targetHeight );
			
			
	        
	        var e1:TitleWindowBoundsEvent =
	            new TitleWindowBoundsEvent(	TitleWindowBoundsEvent.WINDOW_RESIZING,
											false,
											true,
											beforeBounds,
											afterBounds );
			
	        dispatchEvent(e1);
	        
	        // Resize only if not canceled.
	        if( ! (e1.isDefaultPrevented()) )
			{
				width	= afterBounds.width;
				height	= afterBounds.height;
			}
	        event.updateAfterEvent();
		}
		
/**
 *  Called when the user stops resizing a TitleWindow
 *  that has been popped up by either by PopUpManager or
 *  PopUpAnchor.
 */
		protected function resizeHandle_mouseUpHandler( event:Event ):void
		{
            var sbRoot:DisplayObject = systemManager.getSandboxRoot();
        
            sbRoot.removeEventListener(	MouseEvent.MOUSE_MOVE,
										resizeHandle_mouseMoveHandler,
										true );
			
            sbRoot.removeEventListener(	MouseEvent.MOUSE_UP,
										resizeHandle_mouseUpHandler,
										true );
			
            sbRoot.removeEventListener(	SandboxMouseEvent.MOUSE_UP_SOMEWHERE,
										resizeHandle_mouseUpHandler )
                
            systemManager.deployMouseShields( false );	        
	        
	        // Check to see that a resize actually occurred and that the
	        // user did not just click on the resizeHandle
	        if( startBounds )
	        {
	            // Dispatch "windowResizeEnd" event with the starting bounds and current bounds.
	            var endEvent:TitleWindowBoundsEvent =
	                new TitleWindowBoundsEvent(	TitleWindowBoundsEvent.WINDOW_RESIZE_END,
	                                           	false,
												false,
												startBounds,
	                                           	new Rectangle( x, y, width, height ) );
				
	            dispatchEvent( endEvent );
				
	            startBounds = null;
	        }
	        startResizeX = NaN;
	        startResizeY = NaN;			
		}		
	}
}