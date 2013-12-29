using System;
using System.Collections;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Xml.Linq;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace WebApplication1
{
    public partial class CropImage : System.Web.UI.Page
    {
        protected const string IMAGES_FOLDER = @"Images\";
        private const int CROPPEDIMAGE_MAX_WIDTH = 200;
        private const int CROPPEDIMAGE_MAX_HEIGHT = 200;
        protected const int FIXEDIMAGE_MAX_WIDTH = 500;
        protected const int FIXEDIMAGE_MAX_HEIGHT = 500;
        protected const int MAX_TEMPFILES_COUNT = 20;
        protected string fixedSizePhotoName = string.Empty;
        protected int fixedSizePhotoWidth = 0;
        protected int fixedSizePhotoHeight = 0;

        protected string defaultCroppedImageFileNameWithExtension = string.Empty;
        protected int DEFAULT_CROPPEDIMAGE_WIDTH = 200;
        protected int DEFAULT_CROPPEDIMAGE_HEIGHT = 200;
        protected int DEFAULT_CROPPEDIMAGE_LEFT = 0;
        protected int DEFAULT_CROPPEDIMAGE_TOP = 0;

        protected Queue CroppedImageFileNamesQueue;

        protected void Page_Load(object sender, EventArgs e)
        {

            CroppedImageFileNamesQueue = new Queue();
            if (Session["CroppedImageFileNamesQueue"] != null)
            {
                CroppedImageFileNamesQueue = (Queue)Session["CroppedImageFileNamesQueue"];
            }

            if (Request.QueryString["imageName"] == null)
            {
                //Get the fixed size image from original image
                string originalImageFileNameWithExtension = "test.jpg";

                string originalImageFileName = originalImageFileNameWithExtension.Substring(0, originalImageFileNameWithExtension.LastIndexOf("."));
                string imageExtension = originalImageFileNameWithExtension.Substring(originalImageFileNameWithExtension.LastIndexOf(".") + 1);

                System.Drawing.Image originalPhoto = System.Drawing.Image.FromFile(Server.MapPath(IMAGES_FOLDER + originalImageFileNameWithExtension));

                fixedSizePhotoName = originalImageFileName + "_fixed." + imageExtension;

                System.Drawing.Image fixedSizePhoto = null;
                if (File.Exists(Server.MapPath(IMAGES_FOLDER + fixedSizePhotoName)))
                {
                    fixedSizePhoto = System.Drawing.Image.FromFile(Server.MapPath(IMAGES_FOLDER + fixedSizePhotoName));
                }
                else
                {
                    fixedSizePhoto = FixedSize(originalPhoto, FIXEDIMAGE_MAX_WIDTH, FIXEDIMAGE_MAX_HEIGHT);
                    fixedSizePhoto.Save(Server.MapPath(IMAGES_FOLDER + fixedSizePhotoName));
                }
                fixedSizePhotoWidth = fixedSizePhoto.Width;
                fixedSizePhotoHeight = fixedSizePhoto.Height;

                //Crop the image to default size                
                defaultCroppedImageFileNameWithExtension = CropAndReturnNewImageFileNameWithExtension(fixedSizePhotoName, DEFAULT_CROPPEDIMAGE_WIDTH, DEFAULT_CROPPEDIMAGE_HEIGHT, DEFAULT_CROPPEDIMAGE_LEFT, DEFAULT_CROPPEDIMAGE_TOP);
            }
            else
            {
                string originalImageFileNameWithExtension = Request.QueryString["imageName"].ToString();
                int originalImageWidth  = Convert.ToInt32(Request.QueryString["width"]);
                int originalImageHeight = Convert.ToInt32(Request.QueryString["height"]);
                int originalImageLeft = Convert.ToInt32(Request.QueryString["left"]);
                int originalImageTop = Convert.ToInt32(Request.QueryString["top"]);

                string newImageFileNameWithExtension = CropAndReturnNewImageFileNameWithExtension(originalImageFileNameWithExtension, originalImageWidth, originalImageHeight, originalImageLeft, originalImageTop);

                if (Request.QueryString["action"] == null || String.IsNullOrEmpty(Convert.ToString(Request.QueryString["action"])))
                {
                    if (!String.IsNullOrEmpty(newImageFileNameWithExtension))
                    {
                        Response.Clear();
                        Response.Write("http://localhost:12931/Images/" + newImageFileNameWithExtension);
                        Response.End();
                        //Response.ContentType = "image/" + imageExtension;
                        //newImage.Save(Response.OutputStream, imageFormat);
                    }
                    else
                    {
                        Response.Clear();
                        Response.Write("http://localhost:12931/Images/" + originalImageFileNameWithExtension);
                        Response.End();
                    }
                }
                else
                { 
                    //save reference in db, delete temp files and redirect to some other page 
                    try
                    {
                        string originalImageFileName = Path.GetFileNameWithoutExtension(Server.MapPath(IMAGES_FOLDER + originalImageFileNameWithExtension));
                        foreach (string fileFound in Directory.GetFiles(Server.MapPath(IMAGES_FOLDER), originalImageFileName + "*"))
                        {
                            if (fileFound != Server.MapPath(IMAGES_FOLDER + newImageFileNameWithExtension))
                            {
                                File.Delete(fileFound);
                            }
                        }
                    }
                    catch (Exception)
                    { 
                    }
                    Response.End();
                }
            }
            
        }
        protected string CropAndReturnNewImageFileNameWithExtension(string originalImageFileNameWithExtension, int originalImageWidth, int originalImageHeight, int originalImageLeft, int originalImageTop)
        {
            string newImageFileNameWithExtension = String.Empty;
            //Get the original file name without extesnsion
            //string originalImageFileName = originalImageFileNameWithExtension.Substring(0, originalImageFileNameWithExtension.LastIndexOf("."));
            string originalImageFileName = Path.GetFileNameWithoutExtension(Server.MapPath(IMAGES_FOLDER + originalImageFileNameWithExtension));
            //string imageExtension = originalImageFileNameWithExtension.Substring(originalImageFileNameWithExtension.LastIndexOf(".") + 1);
            string imageExtension = Path.GetExtension(Server.MapPath(IMAGES_FOLDER + originalImageFileNameWithExtension));

            //Crop the original image
            System.Drawing.Image newImage = Crop(originalImageFileNameWithExtension, originalImageWidth, originalImageHeight, originalImageLeft, originalImageTop);
            //Form a new image name 
            string newImageFileName = originalImageFileName + Convert.ToString(originalImageWidth) + Convert.ToString(originalImageHeight) + Convert.ToString(originalImageLeft) + Convert.ToString(originalImageTop);
           
            //Find the image format
            System.Drawing.Imaging.ImageFormat imageFormat = ImageFormat.Jpeg;
            if (imageExtension == ".jpg" || imageExtension == ".jpeg")
            {
                imageExtension = ".jpeg";
                imageFormat = ImageFormat.Jpeg;
            }
            else
            {
                imageFormat = ImageFormat.Gif;
            }

            //Save it
            if (newImage != null)
            {
                try
                {
                    newImageFileNameWithExtension = newImageFileName + imageExtension;

                    string fileToDelete = string.Empty;

                    if (CroppedImageFileNamesQueue.Count > MAX_TEMPFILES_COUNT)
                    {
                        fileToDelete = Convert.ToString(CroppedImageFileNamesQueue.Dequeue());
                        File.Delete(Server.MapPath(IMAGES_FOLDER + fileToDelete));
                    }
                    
                    CroppedImageFileNamesQueue.Enqueue(newImageFileNameWithExtension);
                    Session["CroppedImageFileNamesQueue"] = CroppedImageFileNamesQueue;

                    FileStream fs = File.Create(Server.MapPath(IMAGES_FOLDER + newImageFileNameWithExtension));
                    newImage.Save(fs, imageFormat);
                    fs.Dispose();
                }
                catch (Exception ex)
                {

                }
            }
            return newImageFileNameWithExtension;
        }
        protected System.Drawing.Image FixedSize(System.Drawing.Image imgPhoto, int Width, int Height)
        {
            int sourceWidth = imgPhoto.Width;
            int sourceHeight = imgPhoto.Height;
            int sourceX = 0;
            int sourceY = 0;
            int destX = 0;
            int destY = 0;

            float nPercent = 0;
            float nPercentW = 0;
            float nPercentH = 0;

            nPercentW = ((float)Width / (float)sourceWidth);
            nPercentH = ((float)Height / (float)sourceHeight);

            //if we have to pad the height pad both the top and the bottom
            //with the difference between the scaled height and the desired height
            if (nPercentH < nPercentW)
            {
                nPercent = nPercentH;                
            }
            else
            {
                nPercent = nPercentW;                
            }

            int destWidth = (int)(sourceWidth * nPercent);
            int destHeight = (int)(sourceHeight * nPercent);

            Bitmap bmPhoto = new Bitmap(destWidth, destHeight, PixelFormat.Format24bppRgb);
            bmPhoto.SetResolution(imgPhoto.HorizontalResolution, imgPhoto.VerticalResolution);

            Graphics grPhoto = Graphics.FromImage(bmPhoto);
            grPhoto.Clear(Color.White);
            grPhoto.InterpolationMode = InterpolationMode.HighQualityBicubic;

            grPhoto.DrawImage(imgPhoto,
                new Rectangle(destX, destY, destWidth, destHeight),
                new Rectangle(sourceX, sourceY, sourceWidth, sourceHeight),
                GraphicsUnit.Pixel);

            grPhoto.Dispose();
            return bmPhoto;
        }
        /// <summary>
        /// method for cropping an image.
        /// </summary>
        /// <param name="img">the image to crop</param>
        /// <param name="width">new height</param>
        /// <param name="height">new width</param>
        /// <param name="x"></param>
        /// <param name="y"></param>
        /// <returns></returns>
        public System.Drawing.Image Crop(string imgName, int srcWidth, int srcHeight, int srcX, int srcY)
        {
            System.Drawing.Image originalImage = null;
            Bitmap bmp = null;
            Graphics graph = null;
            System.Drawing.Rectangle srcRect;
            System.Drawing.Rectangle destRect;
            int destX = 0;
            int destY = 0;
            int destWidth = 0;
            int destHeight = 0;
            //float nPercent = 0;
            //float nPercentW = 0;
            //float nPercentH = 0;

            try
            {
                originalImage = System.Drawing.Image.FromFile(Server.MapPath(IMAGES_FOLDER + imgName));

                bmp = new Bitmap(CROPPEDIMAGE_MAX_WIDTH, CROPPEDIMAGE_MAX_HEIGHT, PixelFormat.Format24bppRgb);
                bmp.SetResolution(originalImage.HorizontalResolution, originalImage.VerticalResolution);

                graph = Graphics.FromImage(bmp);
                graph.Clear(System.Drawing.Color.White);

                graph.SmoothingMode = SmoothingMode.AntiAlias;
                graph.InterpolationMode = InterpolationMode.HighQualityBicubic;
                graph.PixelOffsetMode = PixelOffsetMode.HighQuality;

                srcRect = new System.Drawing.Rectangle(srcX, srcY, srcWidth, srcHeight);
                //Required only if you have rectangle source image
                //nPercentW = ((float)DEST_WIDTH / (float)srcWidth);
                //nPercentH = ((float)DEST_HEIGHT / (float)srcHeight);
                //if (nPercentH > nPercentW)
                //{
                //    nPercent = nPercentW;
                //}
                //else
                //{
                //    nPercent = nPercentH;
                //}
                //destWidth = (int)(srcWidth * nPercent);
                //destHeight = (int)(srcHeight * nPercent);

                //For square source images
                destWidth = destHeight = (int)(srcWidth * ((float)CROPPEDIMAGE_MAX_WIDTH / (float)srcWidth));

                destRect = new Rectangle(destX, destY, destWidth, destHeight);

                graph.DrawImage(originalImage, destRect, srcRect, GraphicsUnit.Pixel);


                return bmp;
            }
            catch (Exception ex)
            {                
                return null;
            }
            finally
            {
                // Dispose to free up resources
                if (originalImage != null)
                {
                    originalImage.Dispose();
                }
                if (graph != null)
                {
                    graph.Dispose();
                }
            }
        }
       
       
    }
}
