#include "qsiapi.h"
#include <fitsio.h>

class Camera {
public:
	Camera();
	const char *getInfo();
	void takePicture();
private:
	QSICamera cam;
	std::string info;

};

int	WriteFITS(unsigned short *buffer, int cols, int rows, char *filename)
{
	int	status = 0;
	fitsfile	*fits;
	unlink(filename);
	fits_create_file(&fits, filename, &status);
	if (status) {
		std::cerr << "cannot create file " << filename << std::endl;
		return -1;
	}
	long	naxes[2] = { cols, rows };
	fits_create_img(fits, SHORT_IMG, 2, naxes, &status);
	long	fpixel[2] = { 1, 1 };
	fits_write_pix(fits, TUSHORT, fpixel, cols * rows, buffer, &status);
	fits_close_file(fits, &status);
}

void Camera::takePicture()
{
	short binX;
	short binY;
	long xsize;
	long ysize;
	long startX;
	long startY;
	cam.put_BinX(1);
	cam.put_BinY(1);
	// Get the dimensions of the CCD
	cam.get_CameraXSize(&xsize);
	cam.get_CameraYSize(&ysize);
	// Set the exposure to a full frame
	cam.put_StartX(0);
	cam.put_StartY(0);
	cam.put_NumX(xsize);
	cam.put_NumY(ysize);

	bool imageReady = false;
	// Start an exposure, 0 milliseconds long (bias frame), with shutter open
	cam.StartExposure(0.000, true);
	// Poll for image completed
	cam.get_ImageReady(&imageReady);
	while(!imageReady)
	{
		usleep(100);
		cam.get_ImageReady(&imageReady);
	}

	int x,y,z;
	// Get the image dimensions to allocate an image array
	cam.get_ImageArraySize(x, y, z);
	unsigned short* image = new unsigned short[x * y];
	// Retrieve the pending image from the camera
	cam.get_ImageArray(image);

	WriteFITS(image, x, y, "/tmp/picture.fits");
	//vips im_copy qsiimage0.tif junk.png

	delete [] image;
}

const char *Camera::getInfo()
{
	int iNumFound;
	std::string camSerial[QSICamera::MAXCAMERAS];
	std::string camDesc[QSICamera::MAXCAMERAS];
	std::string tmp("");

	info = "QSI SDK Version: ";
	cam.get_DriverInfo(tmp);
	info.append(tmp);
	info.append("\n");

	cam.get_AvailableCameras(camSerial, camDesc, iNumFound);

	if (iNumFound < 1)
	{
		info.append("No cameras found\n");
		return info.c_str();
	}

	info.append("Serial# ");
	info.append(camSerial[0]);
	info.append("\n");

	/*for (int i = 0; i < iNumFound; i++)
	{
		std::cout << camSerial[i] << ":" << camDesc[i] << "\n";
	}*/

	cam.put_SelectCamera(camSerial[0]);

	cam.put_IsMainCamera(true);
	// Connect to the selected camera and retrieve camera parameters
	if (cam.put_Connected(true) == 0)
	{
		info.append("Camera connected.\n");
	} else {
		info.append("failed to connect to camera.\n");
		return info.c_str();
	}

	// Get Model Number
	tmp.clear();
	cam.get_ModelNumber(tmp);
	info.append("Model: ");
	info.append(tmp);
	info.append("\n");

	// Get Camera Description
	tmp.clear();
	cam.get_Description(tmp);
	info.append("Descr: ");
	info.append(tmp);
	info.append("\n");
	return info.c_str();
}

Camera::Camera()
{
	cam.put_UseStructuredExceptions(false);
}

