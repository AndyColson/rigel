#include "qsiapi.h"
#include <fitsio.h>

class Camera {
public:
	Camera();
	~Camera();
	const char *getInfo();
	void takePicture();
private:
	QSICamera cam;
	std::string info;

};

int	WriteFITS(unsigned short *buffer, int cols, int rows, const char *filename)
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
	printf("create_img\n");
	fits_create_img(fits, SHORT_IMG, 2, naxes, &status);
	long	fpixel[2] = { 1, 1 };
	printf("write_pix\n");
	fits_write_pix(fits, TUSHORT, fpixel, cols * rows, buffer, &status);
	printf("close_file\n");
	fits_close_file(fits, &status);
	printf("return\n");
	return 0;
}

void Camera::takePicture()
{
	short binX;
	short binY;
	long xsize;
	long ysize;
	long startX;
	long startY;
	int result;

	cam.put_BinX(1);
	cam.put_BinY(1);
	// Get the dimensions of the CCD
	cam.get_CameraXSize(&xsize);
	cam.get_CameraYSize(&ysize);
	printf("camera size %ld x %ld\n", xsize, ysize);
	// Set the exposure to a full frame
	cam.put_StartX(0);
	cam.put_StartY(0);
	cam.put_NumX(xsize);
	cam.put_NumY(ysize);

	cam.put_PreExposureFlush(QSICamera::FlushNormal);
	cam.put_ManualShutterMode(false);

	bool enabled;
	cam.get_ManualShutterMode(&enabled);
	if (enabled)
	{
		printf("Manual shutter mode enabled\n");
		result = cam.put_ManualShutterOpen(true);
		if (result != 0)
		{
			printf("Failed to open shutter!\n");
		}
	} else {
		printf("Auto shutter mode enabled\n");
	}

	bool imageReady = false;
	// Start an exposure, 0 milliseconds long (bias frame), with shutter open
	printf("starting exposure\n");
	result = cam.StartExposure(5.000, true);
	if (result != 0)
	{
		printf("StartExposure failed: %d\n", result);
	}
	// Poll for image completed
	cam.get_ImageReady(&imageReady);
	while(!imageReady)
	{
		usleep(100);
		cam.get_ImageReady(&imageReady);
	}
	printf("done exposure\n");

	int x,y,z;
	// Get the image dimensions to allocate an image array
	cam.get_ImageArraySize(x, y, z);
	unsigned short* image = new unsigned short[x * y];
	// Retrieve the pending image from the camera
	result = cam.get_ImageArray(image);
	if (result != 0)
	{
		std::cout << "get_ImageArray error \n";
		std::string last("");
		cam.get_LastError(last);
		std::cout << last << "\n";
	}

	printf("saving\n");

	WriteFITS(image, x, y, "/tmp/picture.fits");
	//vips im_copy qsiimage0.tif junk.png

	printf("free\n");
	delete [] image;
	printf("finished\n");
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
	std::string modelNumber;
	cam.get_ModelNumber(modelNumber);
	info.append("Model: ");
	info.append(modelNumber);
	info.append("\n");

	// Get Camera Description
	tmp.clear();
	cam.get_Description(tmp);
	info.append("Descr: ");
	info.append(tmp);
	info.append("\n");


	bool canSetTemp;
	cam.get_CanSetCCDTemperature(&canSetTemp);
	if (canSetTemp)
	{
		info.append("Temperature can be set\n");
		double temp;
		cam.get_CCDTemperature( &temp );
		char buf[100];
		snprintf(buf, sizeof(buf), "%.2f", temp);
		info.append("Current temp: ");
		info.append(buf);
		info.append("\n");
	}

	if (modelNumber.substr(0,1) == "6")
	{
		info.append("Can set Readout Seed\n");
		cam.put_ReadoutSpeed(QSICamera::FastReadout);
	}

	bool hasFilters;
	cam.get_HasFilterWheel(&hasFilters);
	if ( hasFilters)
	{
		info.append("Has filter wheel\n");
	}

	bool hasShutter;
	cam.get_HasShutter(&hasShutter);
	if (hasShutter)
	{
		info.append("Has shutter\n");
	}

	return info.c_str();
}

Camera::~Camera()
{
	printf("Camera DONE\n");
	cam.put_Connected(false);
}

Camera::Camera()
{
	printf("Camera INIT\n");
	cam.put_UseStructuredExceptions(false);
}

