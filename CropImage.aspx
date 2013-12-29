<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="CropImage.aspx.cs" Inherits="WebApplication1.CropImage"  EnableViewState="false"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Crop Image</title>
     <style type="text/css">
        .imgJSselbox{
            position: absolute;
            margin: 0px;
            padding: 0px;
            height:200px;
            width:200px;
            left:0px;
            top:0px;
            visibility:visible;
            border: 1px solid #006;
            color: #fff;            
            background-image:url("Images/selection_area.gif");
            z-index: 20;
            cursor:move;
        }
         .imgJSresizebox{
            position:absolute;
            margin: 0px;
            padding: 0px;
            height:20px;
            width:20px;
            left:180px;
            top:180px;
            visibility:visible;
            border: 1px solid #006;                        
            background-color:Green;
            z-index: 30;
            cursor:nw-resize;
        }
    </style>
    <script type="text/javascript" language="javascript">
    debugger
        var deltaX = 0;
        var deltaY = 0;
        var selObj ;
        var resizeObj ;
        var selObjX;
        var selObjY;       
        var resizeObjX;
        var resizeObjY;
        var selObjWidth;
        var selObjHeight;        
        var resizeObjWidth;
        var resizeObjHeight;
        var evt;
        var imageLeft;
        var imageTop;
        var imageWidth;
        var imageHeight;
        var imageObj;
        var xmlHttp = getXHTTP(); 
        var documentOffsetTop = 0;
        var documentOffsetLeft = 0;
        var documentOffsetPosition = new Array();
        var mouseButton = 0;
        
        function engage(e)
        {
            // if e is null, means the Internet Explorer event model, so get window.event. 
            if(!e) 
            {//Internet Explorer
                e = window.event;                
            }
            if( typeof( e.which ) == 'number' )
            {//Netscape/Mozilla compatible
                mouseButton = e.which;
            } 
            else if( typeof( e.button ) == 'number' ) 
            {//DOM                
                mouseButton = e.button;
            } 
            
            if(mouseButton != 2)
            {              
                selObj.onmousemove = drag;
                resizeObj.onmousemove = resize;
                //for dragging
                //get the difference b/w mouse and edges to be maintained                
                deltaX = e.clientX - parseInt(getStyle(selObj,"left"),10);
                deltaY = e.clientY - parseInt(getStyle(selObj,"top"),10);
            }
        }
        function release(e)
        {
            // if e is null, means the Internet Explorer event model, so get window.event. 
            if(!e) 
            {//Internet Explorer
                e = window.event;                
            }
            if( typeof( e.which ) == 'number' )
            {//Netscape/Mozilla compatible
                mouseButton = e.which;
            } 
            else if( typeof( e.button ) == 'number' ) 
            {//DOM                
                mouseButton = e.button;
            }
            if(mouseButton != 2)
            {              
                selObj.onmousemove = null;
                resizeObj.onmousemove = null;
            }
        }
        function drag(e)
        {     
            // if e is null, means the Internet Explorer event model, so get window.event. 
            if(!e) 
            {//Internet Explorer
                e = window.event;                
            }
            if( typeof( e.which ) == 'number' )
            {//Netscape/Mozilla compatible
                mouseButton = e.which;
            } 
            else if( typeof( e.button ) == 'number' ) 
            {//DOM                
                mouseButton = e.button;
            }
            if(mouseButton != 2)
            {                            
                //This is for dragging   
                selObjX = e.clientX - deltaX;
                selObjY = e.clientY - deltaY;
                
                checkBoundaryConditions("TopLeft");
                
                selObj.style.left = selObjX + "px";
                selObj.style.top = selObjY + "px";
                
                resizeObjX = selObjX + selObjWidth - 20 ;  
                resizeObjY = selObjY + selObjHeight - 20 ;
                resizeObj.style.left =  resizeObjX + "px";
                resizeObj.style.top = resizeObjY + "px";
    
                cropImage();
            }
        }
        
        function resize(e)
        {  
            // if e is null, means the Internet Explorer event model, so get window.event. 
            if(!e) 
            {//Internet Explorer
                e = window.event;                
            }
            if( typeof( e.which ) == 'number' )
            {//Netscape/Mozilla compatible
                mouseButton = e.which;
            } 
            else if( typeof( e.button ) == 'number' ) 
            {//DOM                
                mouseButton = e.button;
            }
            if(mouseButton != 2)
            {
                selObjWidth = e.clientX  - parseInt(getStyle(selObj,"left"),10);
                //If u want rectangle selection box use this
                //selObjHeight =  e.clientY - parseInt(getStyle(selObj,"top"),10);
                //For square box go for this
                selObjHeight =  e.clientY - parseInt(getStyle(selObj,"top"),10);
                if(selObjHeight > selObjWidth)
                {
                    selObjWidth = selObjHeight;
                }
                else
                {
                    selObjHeight = selObjWidth;
                }
                
                checkBoundaryConditions("WidthHeight");
                
                selObj.style.width = selObjWidth + "px";
                selObj.style.height = selObjHeight + "px";   
                
                resizeObjX = selObjX + selObjWidth - 20 ;  
                resizeObjY = selObjY + selObjHeight - 20 ;
                resizeObj.style.left =  resizeObjX + "px";
                resizeObj.style.top = resizeObjY + "px";                 
               
                cropImage();
            }
            
        }
        
        function checkBoundaryConditions(toCheck)
        {
           
            if(toCheck == "TopLeft")
            {
                if(selObjX < imageLeft )
                {
                    selObjX = imageLeft;
                }
                if((selObjX + selObjWidth)  > (imageLeft + imageWidth))
                {
                    selObjX = (imageLeft + imageWidth) - selObjWidth;
                }
                if(selObjY < imageTop )
                {
                    selObjY = imageTop;
                }
                if((selObjY + selObjHeight)  > (imageTop + imageHeight))
                {
                    selObjY = (imageTop + imageHeight) - selObjHeight;
                }
            }
            else
            {
                if((selObjX + selObjWidth) > (imageLeft + imageWidth))
                {
                    selObjWidth = (imageLeft + imageWidth) - selObjX;
                }
                if((selObjY + selObjHeight) > (imageTop + imageHeight))
                {
                    selObjHeight = (imageTop + imageHeight) - selObjY;
                }
                if(selObjWidth < 50)
                {
                    selObjWidth = 50;
                }
                if(selObjHeight < 50)
                {
                    selObjHeight = 50;
                }
            }
        }
        
        function init()
        {
           selObj = document.getElementById("selObj");
           resizeObj = document.getElementById("resizeObj"); 
           selObj.onmousedown = engage;
           resizeObj.onmousedown = engage;
           document.onmouseup = release;           
          
           imageObj =  document.getElementById("testImage");
           imageLeft = parseInt(getStyle(imageObj,"left"),10);
           imageTop = parseInt(getStyle(imageObj,"top"),10);
           imageWidth = parseInt(getStyle(imageObj,"width"),10);
           imageHeight = parseInt(getStyle(imageObj,"height"),10);
            
           // need to know the position in relation to the document as well
           documentOffsetPosition = findPosition(document.getElementById("testImage"));
           imageLeft = imageLeft + documentOffsetPosition[0];
           imageTop = imageTop + documentOffsetPosition[1];
           
           //Offset the selection box
           selObj.style.left = documentOffsetPosition[0] + "px";
           selObj.style.top = documentOffsetPosition[1] + "px";           
           var resizeObjXWithOffset = parseInt(getStyle(resizeObj,"left"),10) +  documentOffsetPosition[0];
           var resizeObjYWithOffset = parseInt(getStyle(resizeObj,"top"),10) +  documentOffsetPosition[1];
           resizeObj.style.left = resizeObjXWithOffset + "px";
           resizeObj.style.top = resizeObjYWithOffset + "px";
           
           selObjX = parseInt(getStyle(selObj,"left"),10);
           selObjY = parseInt(getStyle(selObj,"top"),10);
           selObjWidth = parseInt(getStyle(selObj,"width"),10);
           selObjHeight = parseInt(getStyle(selObj,"height"),10);
           resizeObjWidth = parseInt(getStyle(resizeObj,"width"),10);
           resizeObjHeight = parseInt(getStyle(resizeObj,"height"),10);
           
           
        }
        
        function getStyle(obj,stylePropertyName)
        {
	        if (obj.currentStyle)
	        {
		        var propertyValue = obj.currentStyle[stylePropertyName];
		    }
	        else if (window.getComputedStyle)
	        {	        
		        var propertyValue = document.defaultView.getComputedStyle(obj,null).getPropertyValue(stylePropertyName);
		    }
	        return propertyValue;
        }

        function findPosition( oElement ) 
        {
            if( typeof( oElement.offsetParent ) != 'undefined' ) 
            {
                for( var documentOffsetLeft = 0, documentOffsetTop = 0; oElement; oElement = oElement.offsetParent ) 
                {
                  documentOffsetLeft += oElement.offsetLeft;
                  documentOffsetTop += oElement.offsetTop;
                }
                return [ documentOffsetLeft, documentOffsetTop ];
            }
            else 
            {
                documentOffsetLeft = oElement.x;
                documentOffsetTop = oElement.y ;
                return [ documentOffsetLeft, documentOffsetTop ];
            }
        }
                
        function cropImage()
        {
            var selObjXOffsetted = 0;
            var selObjYOffsetted = 0;           
            if(typeof(documentOffsetPosition[0]) != 'undefined')
            {
                selObjXOffsetted = selObjX - documentOffsetPosition[0];
                selObjYOffsetted = selObjY - documentOffsetPosition[1];
            }
            else
            {
                selObjXOffsetted = selObjX;
                selObjYOffsetted = selObjY;
            }
            var imageName = document.getElementById("hidImageName").value;            
            xmlHttp.open("GET", "CropImage.aspx?imageName="+imageName+"&left="+selObjXOffsetted+"&top="+selObjYOffsetted+"&width="+selObjWidth+"&height="+selObjHeight, true);
            xmlHttp.onreadystatechange = getHttpRes;
            xmlHttp.send(null);            
        }
        
        function getHttpRes() {
	        if (xmlHttp.readyState == 4) {	
	        //alert(xmlHttp.responseText + " and " + xmlHttp.status);       
		        if (xmlHttp.status == 200) {
		            document.getElementById("preview").src = xmlHttp.responseText;		            
		        }		        
	        }
        }
        function getXHTTP() {
          var xhttp;
           try {   // The following "try" blocks get the XMLHTTP object for various browsers…
              xhttp = new ActiveXObject("Msxml2.XMLHTTP");
            } catch (e) {
              try {
                xhttp = new ActiveXObject("Microsoft.XMLHTTP");
              } catch (e2) {
                 // This block handles Mozilla/Firefox browsers...
                try {
                  xhttp = new XMLHttpRequest();
                } catch (e3) {
                  xhttp = false;
                }
              }
            }
          return xhttp; // Return the XMLHTTP object
        }
        
        function saveImage()
        {
            var imageName = document.getElementById("hidImageName").value;
            var selObjXOffsetted = selObjX - documentOffsetPosition[0];
            var selObjYOffsetted = selObjY - documentOffsetPosition[1];
            document.forms[0].action = "CropImage.aspx?imageName="+imageName+"&left="+selObjXOffsetted+"&top="+selObjYOffsetted+"&width="+selObjWidth+"&height="+selObjHeight+"&action=save";
            document.forms[0].submit();
            
            //opener.location.reload(true);
            frameElement.parentNode.style.display = "none";
            frameElement.src = "";
//            if (window.parent && !window.parent.closed) {
//            window.parent.location.reload();
//            } 

            
        }
    </script>
</head>
<body onload="init();"   >
    <form id="CropImageForm" runat="server">
    <div>
        <img src="http://localhost:12931/Images/<%=fixedSizePhotoName%>" id="testImage" style="left:0;top:0;"  width="<%=fixedSizePhotoWidth%>" height="<%=fixedSizePhotoHeight%>"  alt="Original Image" />
        <div id="selObj" class="imgJSselbox" ></div>
        <div id="resizeObj" class="imgJSresizebox" ></div>
        <input id="btnCrop" type="button" value="Crop Image" onclick="cropImage()" />
        <img id="preview" src="http://localhost:12931/Images/<%=defaultCroppedImageFileNameWithExtension%>" alt="Cropped Image" /> 
        <input id="btnSave" type="button" value="Save Image" onclick="saveImage()" />
        <input type="hidden" name="hidImageName" id="hidImageName" value="<%=fixedSizePhotoName%>" />
    </div>
    </form>
    
</body>
</html>
