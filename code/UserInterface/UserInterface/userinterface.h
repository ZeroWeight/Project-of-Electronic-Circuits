#ifndef USERINTERFACE_H
#define USERINTERFACE_H

#include <QtWidgets/QMainWindow>
#include "ui_userinterface.h"
#include <QtWidgets/QPushButton>
#include <QGLWidget>
#include <qgl.h>
#include <GL/GLU.h>

class Painter :public QGLWidget {
	Q_OBJECT
public:
	GLubyte ans[240][320][3] = { 0 };
	Painter (QWidget* parent = 0);
	~Painter ();
protected:
	void resizeGL (int w, int h)override;
	void initializeGL ()override;
	void paintGL () override;
};

class UserInterface : public QMainWindow {
	Q_OBJECT

public:
	UserInterface (QWidget *parent = 0);
	~UserInterface ();
	Painter* paint_area;
private:
	Ui::UserInterfaceClass ui;
};

#endif // USERINTERFACE_H
