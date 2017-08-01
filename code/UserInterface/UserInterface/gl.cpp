#include "userinterface.h"

Painter::Painter (QWidget* parent)
	: QGLWidget (parent) {}

Painter::~Painter () {}

void Painter::paintGL () {
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity ();;
	cv::Mat mat_ori = cv::Mat (240, 320, CV_8UC3, ans);
	cv::Mat mat_des = cv::Mat (240 * size, 320 * size, CV_8UC3);
	cv::resize (mat_ori, mat_des, mat_des.size (), (0, 0), (0, 0), cv::INTER_CUBIC);
	glDrawPixels (640, 480, GL_RGB, GL_UNSIGNED_BYTE, mat_des.data);
}

void Painter::initializeGL () {
	glShadeModel (GL_SMOOTH);
	glClearColor (0.0, 0.0, 0.0, 0.0);
	glClearDepth (1.0);
	glEnable (GL_DEPTH_TEST);
	glDepthFunc (GL_LEQUAL);
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
}
void Painter::resizeGL (int w, int h) {
	glViewport (0, 0, GLint (width ()), GLint (height ()));
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
}