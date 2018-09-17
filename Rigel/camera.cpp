#include "qsiapi.h"
#include <fitsio.h>

class Camera {
public:
	Camera();
	const char *getInfo();
private:
	QSICamera cam;
	std::string info = "";

};

const char *Camera::getInfo()
{
	return info.c_str();
}

Camera::Camera()
{
	cam.put_UseStructuredExceptions(false);
	cam.get_DriverInfo(info);
}

