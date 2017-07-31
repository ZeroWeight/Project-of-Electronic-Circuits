#include "userinterface.h"

Painter::Painter (QWidget* parent)
	: QGLWidget (parent) {}

Painter::~Painter () {}

void Painter::paintGL () {
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity ();;
	for (int i = 0; i < 240; i++)
		for (int j = 0; j < 320; j++)
			if (i < 50 && j < 50) {
				ans[i][j][1] = 255;
				ans[i][j][2] = 0;
				ans[i][j][0] = 255;
			}
			else {
				ans[i][j][1] = 0;
				ans[i][j][2] = 255;
				ans[i][j][0] = 255;
			}

			glDrawPixels (320, 240, GL_RGB, GL_UNSIGNED_BYTE, ans);
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