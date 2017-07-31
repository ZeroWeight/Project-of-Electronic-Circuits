#ifndef USERINTERFACE_H
#define USERINTERFACE_H

#include <QtWidgets/QMainWindow>
#include "ui_userinterface.h"
#include <QtWidgets/QPushButton>
#include <QGLWidget>
#include <QDesktopWidget>
#include <QFile>
#include <QApplication>
#include <QPushButton>
#include <qgl.h>
#include <GL/GLU.h>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>

class Painter :public QGLWidget {
	Q_OBJECT
public:
	int size;
	GLubyte ans[240][320][3] = { 0 };
	Painter (QWidget* parent = 0);
	~Painter ();
protected:
	void resizeGL (int w, int h)override;
	void initializeGL ()override;
	void paintGL () override;
};
typedef QPushButton* Button;
class UserInterface : public QMainWindow {
	Q_OBJECT

public:
	UserInterface (QWidget *parent = 0);
	~UserInterface ();
	Painter* paint_area;
private:
	Ui::UserInterfaceClass ui;
	Button Control_array[6];
};

#endif // USERINTERFACE_H
